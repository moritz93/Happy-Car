-- FORMAT: Je eine Sicht gefolgt von den auf sie bezogenen Regeln



-- Bietet Kundenname, Modellname, Vor. Lieferdatum, Anzahl, Preis und Auftragsnummer aller Aufträge einer Schnittstelle an
CREATE OR REPLACE VIEW Kundensicht AS
	WITH Kundeninfo AS
		(SELECT Vorname, Nachname, Aufträge.KundenID AS KundenID, Aufträge.AID AS Auftrag1 FROM Aufträge JOIN Personen ON Aufträge.KundenID = Personen.PID),
	Modellname AS
		(SELECT Bezeichnung, Aufträge.AID AS Auftrag2 FROM Aufträge JOIN Modelle ON Aufträge.Modell_ID = Modelle.Modell_ID)
	SELECT Vorname, Nachname, tmp.KundenID AS KundenID, Bezeichnung AS Modell, Vorraussichtliches_Lieferdatum, Datum AS Auftrag_erteilt_am, Anzahl, Preis, AID AS Auftragsnummer 
	FROM (SELECT * FROM Kundeninfo JOIN Modellname ON Auftrag1 = Auftrag2) AS tmp JOIN Aufträge on AID = Auftrag1;



-- Erlaubt einem Hersteller sein Teileangebot einzusehen und ggf. anzupassen
CREATE OR REPLACE VIEW Herstellerangebot AS
	WITH Herstellerteile AS
		(SELECT Hersteller.HID AS HID, Firmenname, TeiletypID, Preis, Zeit FROM Hersteller JOIN produzieren ON Hersteller.HID = produzieren.HID)
	SELECT Firmenname, HID AS Herstelleridentifikationsnummer, TeiletypID, Preis, Zeit FROM Herstellerteile;

-- Notwendig da laut Postgres Doku von CREATE RULE:
-- "There is a catch if you try to use conditional rules for view updates: 
-- there must be an unconditional INSTEAD rule for each action you wish to allow on the view."
CREATE OR REPLACE RULE manufacturerCommandI AS ON INSERT TO Herstellerangebot
DO INSTEAD NOTHING;
CREATE OR REPLACE RULE manufacturerCommandU AS ON UPDATE TO Herstellerangebot
DO INSTEAD NOTHING;

CREATE OR REPLACE RULE manufacturerNewPartInInventory AS ON INSERT TO Herstellerangebot 
WHERE EXISTS (SELECT * FROM Autoteiltypen WHERE Autoteiltypen.TeiletypID = NEW.TeiletypID)
DO INSERT INTO produzieren VALUES (NEW.TeiletypID, NEW.Herstelleridentifikationsnummer, NEW.Preis, NEW.Zeit);

CREATE OR REPLACE RULE manufacturerPartUpdatedInInventory AS ON UPDATE TO Herstellerangebot 
-- TeiletypIDs dürfen von Herstellern nicht geändert werden.
-- Möchte ein Hersteller ein Teil komplett durch ein neues ersetzen muss er stattdessen löschen und dann einfügen.
WHERE NEW.TeiletypID = OLD.TeiletypID 
DO ALSO UPDATE produzieren SET HID = NEW.Herstelleridentifikationsnummer, Preis = NEW.Preis, Zeit = NEW.Zeit
	WHERE TeiletypID = OLD.TeiletypID AND HID = OLD.Herstelleridentifikationsnummer;

CREATE OR REPLACE RULE manufacturerDeletePartInInventory AS ON DELETE TO Herstellerangebot
DO INSTEAD DELETE FROM produzieren WHERE TeiletypID = OLD.TeiletypID AND HID = OLD.Herstelleridentifikationsnummer 
	AND Preis = OLD.Preis AND Zeit = OLD.Zeit;



-- Zeigt die aktuellen Bestellungen einem Hersteller an (nicht modifizierbar)
CREATE OR REPLACE VIEW Herstellerbestellungen AS
	SELECT Firmenname, Hersteller.HID AS Herstelleridentifikationsnummer, BID AS Bestellungsnummer, Status AS Bestellungsstatus, 
	bestellt.TeiletypID AS TeiletypID, Bezeichnung AS Teilbezeichnung
	FROM Hersteller JOIN bestellt ON Hersteller.HID = bestellt.HID JOIN Autoteiltypen ON bestellt.TeiletypID = Autoteiltypen.TeiletypID;



-- Ermöglicht einem Teilelagerarbeiter das Einscannen eingegangener Teilelieferungen
CREATE OR REPLACE VIEW Teilelagerarbeitersicht AS
	SELECT BID AS BestellungsID FROM bestellt;

CREATE OR REPLACE RULE scanIn AS ON UPDATE TO Teilelagerarbeitersicht
DO ALSO UPDATE bestellt SET Status = 'ARCHIVIERT' WHERE BID = OLD.BestellungsID AND Status != 'ARCHIVIERT';



-- Mittels dieser Sicht kann ein Autolagerarbeiter den aktuellen Autobestand einsehen
CREATE OR REPLACE VIEW Autolagerarbeitersicht AS
	SELECT KFZ_ID AS Fahrgestellnummer, Bezeichnung AS Modell, Status, Name as Werk
	FROM Autos JOIN Modelle ON Autos.Modell_ID = Modelle.Modell_ID JOIN Werke ON Autos.produziertVon = Werke.WID;



-- Die Schnittstelle über die ein Werksarbeiter Zugriff auf die Werksaufträge hat
CREATE OR REPLACE VIEW Werksarbeitersicht AS
	SELECT WID AS Werknummer, AID AS Auftragsnummer, Status FROM Werksaufträge;

CREATE OR REPLACE RULE factoryU AS ON UPDATE TO Werksarbeitersicht
DO INSTEAD NOTHING;

CREATE OR REPLACE RULE factoryScan AS ON UPDATE TO Werksarbeitersicht
WHERE OLD.Werknummer = NEW.Werknummer AND OLD.Auftragsnummer = NEW.Auftragsnummer
DO ALSO UPDATE Werksaufträge SET Status = 'ARCHIVIERT' WHERE WID = OLD.Werknummer AND AID = OLD.Auftragsnummer AND Status != 'ARCHIVIERT';



-- Die Informationen, die ein LKW Fahrer zur Auslieferung benötigt
CREATE OR REPLACE VIEW LKW_FahrerSicht AS
	SELECT Vorname AS Fahrervorname, Nachname AS Fahrernachname, MID AS FahrerID, liefert.LKW_ID AS LKW_Nummer, Autos.KFZ_ID AS Fahrgestellnummer_Ware,
	liefert.AID AS Auftragsnummer, Aufträge.Status AS Auftragsstatus
	FROM liefert JOIN Personen ON liefert.MID = Personen.PID JOIN Autos ON liefert.KFZ_ID = Autos.KFZ_ID 
		JOIN Aufträge ON liefert.AID = Aufträge.AID;

-- LKW Fahrer dürfen nur den Status auf 'ARCHIVIERT' setzten
CREATE OR REPLACE RULE driverCommandU AS ON UPDATE TO LKW_FahrerSicht
DO INSTEAD NOTHING;

-- Archiviert Auftrag in liefert (durch den ON DELETE DO INSTEAD UPDATE Trigger auf liefert)
-- sobald die bestellten Autos beim Kunden ausgeliefert werden
CREATE OR REPLACE RULE scanDeliveryDate AS ON UPDATE TO LKW_FahrerSicht
WHERE OLD.Fahrervorname = NEW.Fahrervorname AND OLD.Fahrernachname = NEW.Fahrernachname AND OLD.LKW_Nummer = NEW.LKW_Nummer
	AND OLD.Fahrgestellnummer_Ware = NEW.Fahrgestellnummer_Ware AND OLD.Auftragsnummer = NEW.Auftragsnummer AND OLD.FahrerID = NEW.FahrerID
DO ALSO DELETE FROM liefert WHERE liefert.Lieferdatum IS NULL AND liefert.KFZ_ID = OLD.Fahrgestellnummer_Ware AND liefert.AID = OLD.Auftragsnummer AND liefert.MID = OLD.FahrerID;



-- Sicht für Verwaltungsangestellte
CREATE OR REPLACE VIEW Verwaltung AS
	WITH Kundeninfo AS
		(SELECT Vorname, Nachname, Aufträge.AID AS Auftrag1 FROM Aufträge JOIN Personen ON Aufträge.KundenID = Personen.PID),
	Modellname AS
		(SELECT Bezeichnung, Aufträge.AID AS Auftrag2 FROM Aufträge JOIN Modelle ON Aufträge.Modell_ID = Modelle.Modell_ID)
	SELECT Vorname, Nachname, KundenID, Bezeichnung AS Modell, Aufträge.Modell_ID AS Modell_ID, Vorraussichtliches_Lieferdatum, 
	Datum AS Auftrag_erteilt_am, Anzahl, Preis, AID AS Auftragsnummer, MitarbeiterID
	FROM (SELECT * FROM Kundeninfo JOIN Modellname ON Auftrag1 = Auftrag2) AS tmp JOIN Aufträge on AID = Auftrag1;

CREATE OR REPLACE RULE adminInsertNewJob AS ON INSERT TO Verwaltung
DO INSTEAD INSERT INTO Aufträge(Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (NEW.Modell_ID, NEW.Anzahl, NEW.KundenID, NEW.MitarbeiterID);



-- Diese Sicht erlaubt die Einsicht offener Aufträge
CREATE OR REPLACE VIEW offene_Aufträge AS
	WITH offeneAufträge AS
	(SELECT * 
	FROM (SELECT Aufträge.AID, KundenID, Vorraussichtliches_Lieferdatum FROM Aufträge JOIN Kunden ON Aufträge.KundenID = Kunden.PID WHERE Aufträge.status = 'WARTEND') AS auftragT
		JOIN Personen ON auftragT.KundenID = Personen.PID)
	SELECT AID AS "Auftragsnr.", vorraussichtliches_lieferdatum AS "Vorrauss. Lieferung" , Vorname AS "Kundenvorname", Nachname AS "Kundenname", TelNr AS "Tel." FROM offeneAufträge;



-- Sicht auf alle sich in Produktion befindender Aufträge bzw. solcher die in den Werken momentan assembliert werden
CREATE OR REPLACE VIEW Produktion AS
	SELECT WID, AID, Status FROM Werksaufträge GROUP BY AID HAVING Status = 'IN_BEARBEITUNG';



-- Über folgende Sichten können die Archive eingesehen werden:
CREATE OR REPLACE VIEW archivierteAutos AS
	SELECT * FROM Autos WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteAufträge AS
	SELECT * FROM Aufträge WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteWerksaufträge AS
	SELECT * FROM Werksaufträge WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteBestellungen AS
	SELECT * FROM bestellt WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteLieferungen AS
	SELECT * FROM liefert WHERE Lieferdatum IS NOT NULL;



-- Manager können über diese Sichten Rückschlüsse auf Ausgaben bzw. Zeitvergeudung ziehen
--CREATE OR REPLACE VIEW Ausgaben AS
	-- Abweichungen der max preise von den tatsächlichen Preisen angeben -> aggregieren in analysefunktion

--CREATE OR REPLACE VIEW Zeitverzögerungen AS
	-- Möglichst angeben wieviel Verzögerungen in jeder Phase der Abarbeitung entstanden sind und welcher Mitarbeiter gescannt hat

	
-- Personalmanagement -> Sicht die alle Spezialisierungen konsolidiert

-- TODO: Ausnahmen werfen
-- TODO: Überall wo etwas mit Aufträgen gemacht wird darauf achten dass auch ein Auftragsstatus übergeben wird
-- TODO: test spezialisierungen update personal
-- TODO: Sicht fürs Kundeneinfügen




-- Personal liefert einen Überblick über alle momentan im Unternehmen beschäftigten Mitarbeiter,
-- sowie ihre Spezialisierung und deren Attribute, und dient der Umsetzung des Personalmanagements
-- Über die Select Regel wird die Spezialisierung automatisch ermittelt und ausgegeben
-- Das Personalmangement darf Mitarbeiter einstellen und entlassen, sowie ihre Daten anpassen (ausser ihre ID)
CREATE OR REPLACE VIEW Personal AS
	SELECT  Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr, Beschäftigungsbeginn, Gehalt, (date '01-01-2014') AS Führerscheindatum, 
	(integer '13') AS arbeitet_in, (varchar '') AS Spezialisierung FROM (Personen JOIN Mitarbeiter ON Personen.PID = Mitarbeiter.PID)
	WHERE Beschäftigungsende IS NULL;

CREATE OR REPLACE RULE "_RETURN" 
AS ON SELECT TO Personal
DO INSTEAD SELECT  Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr, Beschäftigungsbeginn, Gehalt, Führerscheindatum, WID AS arbeitet_in,
	(CASE 
		WHEN Mitarbeiter.PID  IN (SELECT PID FROM Teilelagerarbeiter) THEN  
			varchar 'TEILELAGERARBEITER' 
		WHEN Mitarbeiter.PID  IN (SELECT PID FROM Autolagerarbeiter) THEN 
			varchar 'AUTOLAGERARBEITER'
		WHEN Mitarbeiter.PID IN (SELECT PID FROM LKW_Fahrer) THEN
			varchar 'LKW FAHRER'
		WHEN Mitarbeiter.PID IN (SELECT PID FROM Werksarbeiter) THEN
			varchar 'WERKSARBEITER'
		WHEN Mitarbeiter.PID IN (SELECT PID FROM Verwaltungsangestellte) THEN
			varchar 'VERWALTUNGSANGESTELLTE'
		WHEN Mitarbeiter.PID IN (SELECT PID FROM Lagerarbeiter 
				      EXCEPT 
				      (SELECT PID FROM (Teilelagerarbeiter FULL OUTER JOIN Autolagerarbeiter USING (PID) ))) THEN
		varchar 'LAGERARBEITER'
	ELSE
		varchar 'MITARBEITER'
	END)
 AS Spezialisierung
FROM (Personen RIGHT OUTER JOIN Mitarbeiter USING (PID) 
		FULL OUTER JOIN LKW_Fahrer USING (PID)
		FULL OUTER JOIN Teilelagerarbeiter USING (PID));

CREATE OR REPLACE FUNCTION insertInPersonal() RETURNS TRIGGER AS
	$$ 
	DECLARE 
	thisID integer;
	BEGIN
	INSERT INTO Personen (Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr) VALUES (NEW.Vorname, NEW.Nachname, NEW.PLZ, NEW.Straße, NEW.Wohnort, NEW.Email, NEW.TelNr);
	thisID=lastval();
	INSERT INTO Mitarbeiter VALUES (thisID, CURRENT_DATE, NEW.Gehalt, NULL);
	CASE NEW.Spezialisierung
		WHEN 'TEILELAGERARBEITER' THEN
			INSERT INTO Lagerarbeiter VALUES (thisID);
			INSERT INTO Teilelagerarbeiter VALUES (thisID, NEW.arbeitet_in);
		WHEN 'AUTOLAGERARBEITER' THEN
			INSERT INTO Lagerarbeiter VALUES (thisID);
			INSERT INTO Autolagerarbeiter VALUES (thisID);
		WHEN 'LKW FAHRER' THEN
			INSERT INTO LKW_Fahrer VALUES (thisID, NEW.Führerscheindatum);
		WHEN 'WERKSARBEITER' THEN
			INSERT INTO Werksarbeiter VALUES (thisID, NEW.arbeitet_in);
		WHEN 'VERWALTUNGSANGESTELLTE' THEN
			INSERT INTO Verwaltungsangestellte VALUES (thisID);
		WHEN 'LAGERARBEITER' THEN
			INSERT INTO Lagerarbeiter VALUES (thisID);
		WHEN 'MITARBEITER' THEN
			RETURN NEW;
		ELSE RAISE EXCEPTION 'Ungültige Spezialisierung: %',NEW.Spezialisierung;
	END CASE;
	RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onInsertInPersonal INSTEAD OF INSERT ON Personal FOR EACH ROW EXECUTE PROCEDURE insertInPersonal();

CREATE OR REPLACE FUNCTION updateOnPersonal() RETURNS TRIGGER AS
	$$
	BEGIN
	IF OLD.PID != NEW.PID THEN RAISE EXCEPTION 'ID of a person cannot be changed.';
	END IF;
	IF NEW.Beschäftigungsbeginn IS NOT NULL THEN RAISE EXCEPTION 'Data of a former employee cannot be changed. Neither can employees be fired via an update operation.';
	END IF;
	UPDATE Personen SET Vorname = NEW.Vorname, Nachname = NEW.Nachname, PLZ = NEW.PLZ, Straße = NEW.Straße, Wohnort = NEW.Wohnort, Email = NEW.Email, TelNr = NEW.TelNr
		WHERE PID = NEW.PID;
		
	UPDATE Mitarbeiter SET Beschäftigungsbeginn = NEW.Beschäftigungsbeginn, Gehalt = NEW.Gehalt
	WHERE PID = NEW.PID;
	IF OLD.Spezialisierung = NEW.Spezialisierung THEN
		CASE NEW.Spezialisierung 
			WHEN 'TEILELAGERARBEITER' THEN
				UPDATE Teilelagerarbeiter SET WID = NEW.arbeitet_in WHERE PID = NEW.PID;
			WHEN 'AUTOLAGERARBEITER' THEN -- nichts zu updaten
			WHEN 'LKW FAHRER' THEN
				UPDATE LKW_Fahrer SET Führerscheindatum = NEW.Führerscheindatum WHERE PID = NEW.PID;
			WHEN 'WERKSARBEITER' THEN
				UPDATE Werksarbeiter SET WID = NEW.arbeitet_in WHERE PID = NEW.PID;
			WHEN 'VERWALTUNGSANGESTELLTE' THEN -- nichts zu updaten
			WHEN 'LAGERARBEITER' THEN -- nichts zu updaten
			WHEN 'MITARBEITER' THEN -- nichts zu updaten
			ELSE RAISE EXCEPTION 'Ungültige Spezialisierung: %',NEW.Spezialisierung;
		END CASE;
	ELSE
		CASE OLD.Spezialisierung
			WHEN 'TEILELAGERARBEITER' THEN
				DELETE FROM Teilelagerarbeiter WHERE PID = NEW.PID;
			WHEN 'LKW FAHRER' THEN
				DELETE FROM LKW_Fahrer WHERE PID = NEW.PID;
			WHEN 'WERKSARBEITER' THEN
				DELETE FROM Werksarbeiter WHERE PID = NEW.PID;
			WHEN 'VERWALTUNGSANGESTELLTE' THEN
				DELETE FROM Verwaltungsangestellte WHERE PID = NEW.PID;
			WHEN 'LAGERARBEITER' THEN
				DELETE FROM Lagerarbeiter WHERE PID = NEW.PID;
			WHEN 'MITARBEITER' THEN -- nichts zu löschen
			ELSE RAISE EXCEPTION 'Some inconsistent state was reached.';
		END CASE;
		CASE NEW.Spezialisierung
			WHEN 'TEILELAGERARBEITER' THEN
				INSERT INTO Lagerarbeiter VALUES (thisID);
				INSERT INTO Teilelagerarbeiter VALUES (thisID, NEW.arbeitet_in);
			WHEN 'AUTOLAGERARBEITER' THEN
				INSERT INTO Lagerarbeiter VALUES (thisID);
				INSERT INTO Autolagerarbeiter VALUES (thisID);
			WHEN 'LKW FAHRER' THEN
				INSERT INTO LKW_Fahrer VALUES (thisID, NEW.Führerscheindatum);
			WHEN 'WERKSARBEITER' THEN
				INSERT INTO Werksarbeiter VALUES (thisID, NEW.arbeitet_in);
			WHEN 'VERWALTUNGSANGESTELLTE' THEN
				INSERT INTO Verwaltungsangestellte VALUES (thisID);
			WHEN 'LAGERARBEITER' THEN
				INSERT INTO Lagerarbeiter VALUES (thisID);
			WHEN 'MITARBEITER' THEN
			RETURN NEW;
			ELSE RAISE EXCEPTION 'Ungültige Spezialisierung: %',NEW.Spezialisierung;
		END CASE;
	END IF;
	RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onUpdateOnPersonal INSTEAD OF UPDATE ON Personal FOR EACH ROW EXECUTE PROCEDURE updateOnPersonal();

-- Löschen bzw. entlassen eines Mitarbeiters kommt einer Archivierung gleich, die durch die Setzung des Beschäftigungsendes realisiert wird.
CREATE OR REPLACE FUNCTION deleteFromPersonal() RETURNS TRIGGER AS
	$$
	BEGIN
	CASE OLD.Spezialisierung 
		WHEN 'TEILELAGERARBEITER' THEN
			DELETE FROM Teilelagerarbeiter WHERE PID = NEW.PID;
		WHEN 'LKW FAHRER' THEN
			DELETE FROM LKW_Fahrer WHERE PID = NEW.PID;
		WHEN 'WERKSARBEITER' THEN
			DELETE FROM Werksarbeiter WHERE PID = NEW.PID;
		WHEN 'VERWALTUNGSANGESTELLTE' THEN
			DELETE FROM Verwaltungsangestellte WHERE PID = NEW.PID;
		WHEN 'LAGERARBEITER' THEN
			DELETE FROM Lagerarbeiter WHERE PID = NEW.PID;
		WHEN 'MITARBEITER' THEN -- nichts zu löschen
		ELSE RAISE EXCEPTION 'Some inconsistent state was reached.';
	END CASE;
	UPDATE Mitarbeiter SET Beschäftigungsende = now() WHERE PID = OLD.PID;
	RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onDeleteFromPersonal INSTEAD OF DELETE ON Personal FOR EACH ROW EXECUTE PROCEDURE deleteFromPersonal();



-- Ingenieure können über diese Sichten neue Teiletypen einführen oder anpassen, aber nicht löschen,
-- da dadurch Informationen vergangener Aufträge verloren gehen könnten.
-- Die TeiletypID, die beim Einfügen angegeben wird, wird ignoriert, da diese eine Serial ist.
CREATE OR REPLACE VIEW IngenieursichtMotoren AS
	SELECT Bezeichnung, TeiletypID, maxPreis, PS, Drehzahl, Verbrauch, Spritart
	FROM Autoteiltypen JOIN Motoren USING (TeiletypID);

CREATE OR REPLACE VIEW IngenieursichtKarosserien AS
	SELECT Bezeichnung, TeiletypID, maxPreis, Farbe, Material, Höhe, Breite, Länge
	FROM Autoteiltypen JOIN Karosserien USING (TeiletypID);

CREATE OR REPLACE VIEW IngenieursichtTüren AS
	SELECT Bezeichnung, TeiletypID, maxPreis, Farbe, Türart
	FROM Autoteiltypen JOIN Türen USING (TeiletypID);

CREATE OR REPLACE VIEW IngenieursichtFenster AS
	SELECT Bezeichnung, TeiletypID, maxPreis, Tönung, Glasart
	FROM Autoteiltypen JOIN Fenster USING (TeiletypID);

CREATE OR REPLACE VIEW IngenieursichtReifen AS
	SELECT Bezeichnung, TeiletypID, maxPreis, Farbe, Zoll, Felgenmaterial
	FROM Autoteiltypen JOIN Reifen USING (TeiletypID);

CREATE OR REPLACE RULE insertMotor AS ON INSERT TO IngenieursichtMotoren
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Motoren VALUES (lastVal(), NEW.PS, NEW.Drehzahl, NEW.Verbrauch, NEW.Spritart));

CREATE OR REPLACE RULE insertKarosserie AS ON INSERT TO IngenieursichtKarosserien
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Karosserien VALUES (lastVal(), NEW.Farbe, NEW.Material, NEW.Höhe, NEW.Breite, NEW.Länge));

CREATE OR REPLACE RULE insertTür AS ON INSERT TO IngenieursichtTüren
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Türen VALUES (lastVal(), Farbe, Türart));

CREATE OR REPLACE RULE insertFenster AS ON INSERT TO IngenieursichtFenster
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Fenster VALUES (lastVal(), NEW.Tönung, NEW.Glasart));

CREATE OR REPLACE RULE insertReifen AS ON INSERT TO IngenieursichtReifen
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Reifen VALUES (lastVal(), NEW.Farbe, NEW.Zoll, NEW.Felgenmaterial));

CREATE OR REPLACE RULE updateMotor AS ON UPDATE TO IngenieursichtMotoren
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Motoren VALUES (lastVal(), NEW.PS, NEW.Drehzahl, NEW.Verbrauch, NEW.Spritart));

CREATE OR REPLACE RULE insertKarosserie AS ON INSERT TO IngenieursichtKarosserien
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Karosserien VALUES (lastVal(), NEW.Farbe, NEW.Material, NEW.Höhe, NEW.Breite, NEW.Länge));

CREATE OR REPLACE RULE insertTür AS ON INSERT TO IngenieursichtTüren
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Türen VALUES (lastVal(), Farbe, Türart));

CREATE OR REPLACE RULE insertFenster AS ON INSERT TO IngenieursichtFenster
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Fenster VALUES (lastVal(), NEW.Tönung, NEW.Glasart));

CREATE OR REPLACE RULE insertReifen AS ON INSERT TO IngenieursichtReifen
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Reifen VALUES (lastVal(), NEW.Farbe, NEW.Zoll, NEW.Felgenmaterial));