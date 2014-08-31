-- FORMAT: Je eine Sicht gefolgt von den auf sie bezogenen Regeln



-- Bietet Kundenname, Modellname, Vor. Lieferdatum, Anzahl, Preis und Auftragsnummer aller Aufträge (offen wie archiviert) einer Schnittstelle an
CREATE OR REPLACE VIEW Kundensicht AS
	WITH Kundeninfo AS
		(SELECT Vorname, Nachname, Aufträge.KundenID AS KundenID, Aufträge.Status AS Auftragsstatus, Aufträge.AID AS Auftrag1 FROM Aufträge JOIN Personen ON Aufträge.KundenID = Personen.PID),
	Modellname AS
		(SELECT Bezeichnung, Aufträge.AID AS Auftrag2 FROM Aufträge JOIN Modelle ON Aufträge.Modell_ID = Modelle.Modell_ID)
	SELECT Vorname, Nachname, tmp.KundenID AS KundenID, Bezeichnung AS Modell, Vorraussichtliches_Lieferdatum, Datum AS Auftrag_erteilt_am, Anzahl, Preis, AID AS Auftragsnummer, Auftragsstatus
	FROM (SELECT * FROM Kundeninfo JOIN Modellname ON Auftrag1 = Auftrag2) AS tmp JOIN Aufträge on AID = Auftrag1;



-- Diese Sicht erlaubt die Einsicht offener Aufträge
CREATE OR REPLACE VIEW offene_Aufträge AS
	WITH offeneAufträge AS
	(SELECT * 
	FROM (SELECT Aufträge.AID, KundenID, Vorraussichtliches_Lieferdatum FROM Aufträge JOIN Kunden ON Aufträge.KundenID = Kunden.PID WHERE Aufträge.status = 'WARTEND') AS auftragT
		JOIN Personen ON auftragT.KundenID = Personen.PID)
	SELECT AID AS "Auftragsnr.", vorraussichtliches_lieferdatum AS "Vorrauss. Lieferung" , Vorname AS "Kundenvorname", Nachname AS "Kundenname", TelNr AS "Tel." FROM offeneAufträge;



-- Erlaubt einem Hersteller sein Teileangebot einzusehen und ggf. anzupassen
CREATE OR REPLACE VIEW Herstellerangebot AS
	WITH Herstellerteile AS
		(SELECT Hersteller.HID AS HID, Firmenname, TeiletypID, Bezeichnung, Preis, Zeit FROM Hersteller JOIN produzieren ON Hersteller.HID = produzieren.HID 
		JOIN Autoteiltypen USING (TeiletypID))
	SELECT Firmenname, HID AS HerstellerID, TeiletypID, Bezeichnung, Preis, Zeit FROM Herstellerteile;

-- Notwendig da laut Postgres Doku von CREATE RULE:
-- "There is a catch if you try to use conditional rules for view updates: 
-- there must be an unconditional INSTEAD rule for each action you wish to allow on the view."
CREATE OR REPLACE RULE manufacturerCommandI AS ON INSERT TO Herstellerangebot
DO INSTEAD NOTHING;
CREATE OR REPLACE RULE manufacturerCommandU AS ON UPDATE TO Herstellerangebot
DO INSTEAD NOTHING;

CREATE OR REPLACE RULE manufacturerNewPartInInventory AS ON INSERT TO Herstellerangebot 
WHERE EXISTS (SELECT * FROM Autoteiltypen WHERE Autoteiltypen.TeiletypID = NEW.TeiletypID)
DO INSERT INTO produzieren VALUES (NEW.TeiletypID, NEW.HerstellerID, NEW.Preis, NEW.Zeit);

CREATE OR REPLACE RULE manufacturerPartUpdatedInInventory AS ON UPDATE TO Herstellerangebot 
-- TeiletypIDs dürfen von Herstellern nicht geändert werden.
-- Möchte ein Hersteller ein Teil komplett durch ein neues ersetzen muss er stattdessen löschen und dann einfügen.
WHERE NEW.TeiletypID = OLD.TeiletypID 
DO ALSO UPDATE produzieren SET HID = NEW.HerstellerID, Preis = NEW.Preis, Zeit = NEW.Zeit
	WHERE TeiletypID = OLD.TeiletypID AND HID = OLD.HerstellerID;

CREATE OR REPLACE RULE manufacturerDeletePartInInventory AS ON DELETE TO Herstellerangebot
DO INSTEAD DELETE FROM produzieren WHERE TeiletypID = OLD.TeiletypID AND HID = OLD.HerstellerID
	AND Preis = OLD.Preis AND Zeit = OLD.Zeit;



-- Zeigt die aktuellen Bestellungen einem Hersteller an (nicht modifizierbar)
CREATE OR REPLACE VIEW Herstellerbestellungen AS
	SELECT Firmenname, Hersteller.HID AS HerstellerID, BID AS Bestellungsnummer, Status AS Bestellungsstatus, 
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
-- Diese führen einen Scan durch sobald alle Autos eines Werksauftrags produziert wurden um das Produktionsende zu vermerken
-- Es ist ihnen nicht gestattet Werk- oder Auftragsnummer zu ändern.
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



-- Erlaubt das Hinzufügen von Großhändlern
CREATE OR REPLACE VIEW Großhändlersicht AS
	SELECT GID AS GroßhändlerID, Firmenname, Straße, PLZ, Ort, Rabatt FROM Großhändler;

CREATE OR REPLACE RULE insertGH AS ON INSERT TO Großhändlersicht
DO INSTEAD INSERT INTO Großhändler(Firmenname, Straße, PLZ, Ort, Rabatt) VALUES (NEW.Firmenname, NEW.Straße, NEW.PLZ, NEW.Ort, NEW.Rabatt);

CREATE OR REPLACE RULE updateGH AS ON UPDATE TO Großhändlersicht
DO INSTEAD UPDATE Großhändler SET Firmenname = NEW.Firmenname, Straße = NEW.Straße, PLZ = NEW.PLZ, Ort = NEW.Ort, Rabatt = NEW.Rabatt
WHERE GID = OLD.GroßhändlerID;

-- Nur Großhändler, die noch keine Kontaktperson haben können gelöscht werden.
CREATE OR REPLACE RULE deleteGH AS ON DELETE TO Großhändlersicht
DO INSTEAD DELETE FROM Großhändler WHERE GID = OLD.GroßhändlerID;



-- Sicht für Verwaltungsangestellte, die Aufträge entgegen nehmen
CREATE OR REPLACE VIEW VerwaltungAuftragssicht AS
	WITH Kundeninfo AS
		(SELECT Vorname, Nachname, Aufträge.AID AS Auftrag1 FROM Aufträge JOIN Personen ON Aufträge.KundenID = Personen.PID),
	Modellname AS
		(SELECT Bezeichnung, Aufträge.AID AS Auftrag2 FROM Aufträge JOIN Modelle ON Aufträge.Modell_ID = Modelle.Modell_ID)
	SELECT Vorname, Nachname, KundenID, Bezeichnung AS Modell, Aufträge.Modell_ID AS Modell_ID, Vorraussichtliches_Lieferdatum, 
	Datum AS Auftrag_erteilt_am, Anzahl, Preis, AID AS Auftragsnummer, MitarbeiterID
	FROM (SELECT * FROM Kundeninfo JOIN Modellname ON Auftrag1 = Auftrag2) AS tmp JOIN Aufträge on AID = Auftrag1;

CREATE OR REPLACE RULE adminInsertNewJob AS ON INSERT TO VerwaltungAuftragssicht
DO INSTEAD INSERT INTO Aufträge(Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (NEW.Modell_ID, NEW.Anzahl, NEW.KundenID, NEW.MitarbeiterID);



-- Sicht für Verwaltungsangestellte, die Kunden ins System aufnehmen sowie ihre Daten anpassen
-- Kunden können aus Nachverfolgungsgründen nicht gelöscht werden, ausser sie haben noch keinen Auftrag aufgegeben
-- GroßhändlerID ist 0 bei Privatkunden
CREATE OR REPLACE VIEW VerwaltungKundenaufnahme AS
	SELECT PID, Vorname, Nachname, (varchar '') AS Kundenart, Distanz, PLZ, Straße, Wohnort, Email, TelNR, (integer '0') AS GroßhändlerID FROM Kunden JOIN Personen USING (PID);

CREATE OR REPLACE RULE "_RETURN" 
AS ON SELECT TO VerwaltungKundenaufnahme
DO INSTEAD SELECT PID, Vorname, Nachname,
	(CASE 
		WHEN PID  IN (SELECT PID FROM Privatkunden) THEN  
			varchar 'PRIVATKUNDE'
		WHEN PID  IN (SELECT PID FROM Kontaktpersonen) THEN 
			varchar 'KONTAKTPERSON'
		ELSE varchar 'Kein Kunde oder noch nicht in Kunden Tabelle.'
	END) AS Kundenart, Distanz, PLZ, Straße, Wohnort, Email, TelNR, GID AS GroßhändlerID
FROM Kunden JOIN Personen USING (PID) FULL OUTER JOIN Kontaktpersonen USING (PID);

CREATE OR REPLACE FUNCTION insertNewCustomer() RETURNS TRIGGER AS
	$$ 
	DECLARE 
	thisID integer;
	BEGIN
	INSERT INTO Kunden (Distanz) VALUES (NEW.Distanz);
	thisID=lastval();
	CASE NEW.Kundenart
		WHEN 'PRIVATKUNDE' THEN
			INSERT INTO Privatkunden VALUES (thisID);
		WHEN 'KONTAKTPERSON' THEN
			INSERT INTO Kontaktpersonen VALUES (thisID, NEW.GroßhändlerID);
		ELSE RAISE EXCEPTION 'Ungültige Kundenart: %', NEW.Kundenart;
	END CASE;
	RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onInsertNewCustomer INSTEAD OF INSERT ON VerwaltungKundenaufnahme FOR EACH ROW EXECUTE PROCEDURE insertNewCustomer();

CREATE OR REPLACE FUNCTION updateCustomer() RETURNS TRIGGER AS
	$$
	BEGIN
	IF OLD.PID != NEW.PID THEN RAISE EXCEPTION 'ID of a customer cannot be changed.';
	END IF;
	UPDATE Kunden SET Distanz = NEW.Distanz WHERE PID = NEW.PID;
	IF OLD.Kundenart = NEW.Kundenart THEN
		CASE NEW.Kundenart
			WHEN 'PRIVATKUNDE' THEN -- nichts zu updaten
			WHEN 'KONTAKTPERSON' THEN
				UPDATE Kontaktpersonen SET GID = NEW.GID;
			ELSE RAISE EXCEPTION 'Ungültige Kundenart: %', NEW.Kundenart;
		END CASE;
	ELSE
		CASE OLD.Kundenart
			WHEN 'PRIVATKUNDE' THEN
				DELETE FROM Privatkunden WHERE PID = OLD.PID;
			WHEN 'KONTAKTPERSON' THEN
				DELETE FROM Kontaktpersonen WHERE PID = OLD.PID;
			ELSE RAISE EXCEPTION 'Some inconsistent state was reached.';
		END CASE;
		CASE NEW.Kundenart
			WHEN 'PRIVATKUNDE' THEN
				INSERT INTO Privatkunden VALUES (NEW.PID);
			WHEN 'KONTAKTPERSON' THEN
				INSERT INTO Kontaktpersonen VALUES (NEW.PID, NEW.GroßhändlerID);
			ELSE RAISE EXCEPTION 'Ungültige Kundenart: %',NEW.Kundenart;
		END CASE;
	END IF;
	RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onUpdateCustomer INSTEAD OF UPDATE ON VerwaltungKundenaufnahme FOR EACH ROW EXECUTE PROCEDURE updateCustomer();

CREATE OR REPLACE FUNCTION deleteCustomer() RETURNS TRIGGER AS
	$$
	BEGIN
	CASE OLD.Kundenart
		WHEN 'PRIVATKUNDE' THEN
			DELETE FROM Privatkunden WHERE PID = OLD.PID;
		WHEN 'KONTAKTPERSON' THEN
			DELETE FROM Kontaktpersonen WHERE PID = OLD.PID;
		ELSE RAISE EXCEPTION 'Some inconsistent state was reached.';
	END CASE;
	DELETE FROM Kunden WHERE PID = OLD.PID;
	RETURN OLD;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onDeleteCustomer INSTEAD OF DELETE ON VerwaltungKundenaufnahme FOR EACH ROW EXECUTE PROCEDURE deleteCustomer();



-- Sicht auf alle sich in Produktion befindender Aufträge bzw. solcher die in den Werken momentan assembliert werden
CREATE OR REPLACE VIEW Produktion AS
	SELECT WID, AID, Status FROM Werksaufträge GROUP BY AID HAVING Status = 'IN_BEARBEITUNG';



-- Sicht auf alle Fahrzeuge in der LKW Fahrzeugflotte
-- Updates ergeben keinen Sinn, da das Kaufdatum nie angepasst wird
CREATE OR REPLACE VIEW Fuhrpark AS
	SELECT * FROM LKWs;

CREATE OR REPLACE RULE newVehicle AS ON INSERT TO Fuhrpark
DO INSTEAD INSERT INTO LKWs(Kaufdatum) VALUES (NEW.Kaufdatum);

CREATE OR REPLACE RULE deleteVehicle AS ON DELETE TO Fuhrpark
DO INSTEAD DELETE FROM LKWs WHERE LKW_ID = OLD.LKW_ID;



-- Architektur erlaubt das Bauen neuer Werke sowie Einsicht aktueller Firmengebäude
CREATE OR REPLACE VIEW Architektur AS
	SELECT * FROM Werke;

CREATE OR REPLACE RULE newFactory AS ON INSERT TO Architektur
DO INSTEAD INSERT INTO Werke(Name) VALUES (NEW.Name);



-- Teilelager liefert eine Übersicht über alle aktuell in den Lagern vorhandenen Teilen
CREATE OR REPLACE VIEW Teilelager AS
	SELECT TeileID, TeiletypID, Bezeichnung, lagert_in, Lieferdatum, AID as AuftragsID
	FROM Autoteile JOIN Autoteiltypen USING (TeiletypID);



-- Modellsicht ermöglicht einfügen neuer Modelle
-- Preis und Bezeichnung können angepasst werden
-- Modelle können nicht ohne weiteres gelöscht werden
-- Teile eines Modells müssen über die Modellteilesicht eingefügt werden
CREATE OR REPLACE VIEW Modellsicht AS
	SELECT * FROM Modelle;

CREATE OR REPLACE RULE modelInsert AS ON INSERT TO Modellsicht
DO INSTEAD INSERT INTO Modelle(Preis, Bezeichnung) VALUES (NEW.Preis, NEW.Bezeichnung);

CREATE OR REPLACE RULE modelUpdate AS ON UPDATE TO Modellsicht
DO INSTEAD UPDATE Modelle SET Preis = NEW.Preis, Bezeichnung = NEW.Bezeichnung
	WHERE Modell_ID = OLD.Modell_ID;



-- Über die Modellteilesicht können neue Teile eines Modells eingefügt oder entfernt,
-- sowie die Anzahl bestehender angepasst werden.
CREATE OR REPLACE VIEW Modellteilesicht AS
	SELECT * FROM Modellteile;

CREATE OR REPLACE RULE modelPartAddition AS ON INSERT TO Modellteilesicht
DO INSTEAD INSERT INTO Modellteile VALUES (NEW.Modell_ID, NEW.TeiletypID, NEW.Anzahl);

CREATE OR REPLACE RULE modelPartAdjust AS ON UPDATE TO Modellteilesicht
DO INSTEAD UPDATE Modellteile SET Anzahl = NEW.Anzahl
WHERE Modell_ID = OLD.Modell_ID AND TeiletypID = OLD.TeiletypID;

CREATE OR REPLACE RULE modelPartDelete AS ON DELETE TO Modellteilesicht
DO INSTEAD DELETE FROM Modellteile WHERE Modell_ID = OLD.Modell_ID AND TeiletypID = OLD.TeiletypID;



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
				DELETE FROM Teilelagerarbeiter WHERE PID = OLD.PID;
				DELETE FROM Lagerarbeiter WHERE PID = OLD.PID;
			WHEN 'AUTOLAGERARBEITER' THEN
				DELETE FROM Autolagerarbeiter WHERE PID = OLD.PID;
				DELETE FROM Lagerarbeiter WHERE PID = OLD.PID;
			WHEN 'LKW FAHRER' THEN
				DELETE FROM LKW_Fahrer WHERE PID = OLD.PID;
			WHEN 'WERKSARBEITER' THEN
				DELETE FROM Werksarbeiter WHERE PID = OLD.PID;
			WHEN 'VERWALTUNGSANGESTELLTE' THEN
				DELETE FROM Verwaltungsangestellte WHERE PID = OLD.PID;
			WHEN 'LAGERARBEITER' THEN
				DELETE FROM Lagerarbeiter WHERE PID = OLD.PID;
			WHEN 'MITARBEITER' THEN -- nichts zu löschen
			ELSE RAISE EXCEPTION 'Some inconsistent state was reached.';
		END CASE;
		CASE NEW.Spezialisierung
			WHEN 'TEILELAGERARBEITER' THEN
				INSERT INTO Lagerarbeiter VALUES (NEW.PID);
				INSERT INTO Teilelagerarbeiter VALUES (NEW.PID, NEW.arbeitet_in);
			WHEN 'AUTOLAGERARBEITER' THEN
				INSERT INTO Lagerarbeiter VALUES (NEW.PID);
				INSERT INTO Autolagerarbeiter VALUES (NEW.PID);
			WHEN 'LKW FAHRER' THEN
				INSERT INTO LKW_Fahrer VALUES (NEW.PID, NEW.Führerscheindatum);
			WHEN 'WERKSARBEITER' THEN
				INSERT INTO Werksarbeiter VALUES (NEW.PID, NEW.arbeitet_in);
			WHEN 'VERWALTUNGSANGESTELLTE' THEN
				INSERT INTO Verwaltungsangestellte VALUES (NEW.PID);
			WHEN 'LAGERARBEITER' THEN
				INSERT INTO Lagerarbeiter VALUES (NEW.PID);
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
	RETURN OLD;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onDeleteFromPersonal INSTEAD OF DELETE ON Personal FOR EACH ROW EXECUTE PROCEDURE deleteFromPersonal();



-- Ingenieure können über diese Sichten neue Teiletypen einführen oder anpassen, aber nicht löschen,
-- da dadurch Informationen vergangener Aufträge verloren gehen könnten.
-- Die TeiletypID, die beim Einfügen angegeben wird, wird ignoriert, da diese eine Serial ist.
-- Die Entscheidung fünf Sichten statt nur einer anzulegen beruht auf der sonst hohen Anzahl von Null Values,
-- da jedes Teil ja nur eine Spezialisierung hat.
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
	INSERT INTO Türen VALUES (lastVal(), NEW.Farbe, NEW.Türart));

CREATE OR REPLACE RULE insertFenster AS ON INSERT TO IngenieursichtFenster
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Fenster VALUES (lastVal(), NEW.Tönung, NEW.Glasart));

CREATE OR REPLACE RULE insertReifen AS ON INSERT TO IngenieursichtReifen
DO INSTEAD (INSERT INTO Autoteiltypen(maxPreis, Bezeichnung) VALUES (NEW.maxPreis, NEW.Bezeichnung);
	INSERT INTO Reifen VALUES (lastVal(), NEW.Farbe, NEW.Zoll, NEW.Felgenmaterial));

CREATE OR REPLACE RULE updateMotor AS ON UPDATE TO IngenieursichtMotoren
DO INSTEAD (UPDATE Autoteiltypen SET maxPreis = NEW.maxPreis, Bezeichnung = NEW.Bezeichnung WHERE TeiletypID = OLD.TeiletypID;
	UPDATE Motoren SET PS = NEW.PS, Drehzahl = NEW.Drehzahl, Verbrauch = NEW.Verbrauch, Spritart = NEW.Spritart 
	WHERE TeiletypID = NEW.TeiletypID);

CREATE OR REPLACE RULE updateKarosserie AS ON UPDATE TO IngenieursichtKarosserien
DO INSTEAD (UPDATE Autoteiltypen SET maxPreis = NEW.maxPreis, Bezeichnung = NEW.Bezeichnung WHERE TeiletypID = OLD.TeiletypID;
	UPDATE Karosserien SET Farbe = NEW.Farbe, Material = NEW.Material, Höhe = NEW.Höhe, Breite = NEW.Breite, Länge = NEW.Länge
	WHERE TeiletypID = NEW.TeiletypID);

CREATE OR REPLACE RULE updateTür AS ON UPDATE TO IngenieursichtTüren
DO INSTEAD (UPDATE Autoteiltypen SET maxPreis = NEW.maxPreis, Bezeichnung = NEW.Bezeichnung WHERE TeiletypID = OLD.TeiletypID;
	UPDATE Türen SET Farbe = NEW.Farbe, Türart = NEW.Türart
	WHERE TeiletypID = NEW.TeiletypID);
	
CREATE OR REPLACE RULE updateFenster AS ON UPDATE TO IngenieursichtFenster
DO INSTEAD (UPDATE Autoteiltypen SET maxPreis = NEW.maxPreis, Bezeichnung = NEW.Bezeichnung WHERE TeiletypID = OLD.TeiletypID;
	UPDATE Fenster SET Tönung = NEW.Tönung, Glasart = NEW.Glasart
	WHERE TeiletypID = NEW.TeiletypID);

CREATE OR REPLACE RULE updateReifen AS ON UPDATE TO IngenieursichtReifen
DO INSTEAD (UPDATE Autoteiltypen SET maxPreis = NEW.maxPreis, Bezeichnung = NEW.Bezeichnung WHERE TeiletypID = OLD.TeiletypID;
	UPDATE Reifen SET Farbe = NEW.Farbe, Zoll = NEW.Zoll, Felgenmaterial = NEW.Felgenmaterial
	WHERE TeiletypID = NEW.TeiletypID);



-- Über folgende Sichten können die Archive eingesehen werden:
CREATE OR REPLACE VIEW archivierteAutos AS
	SELECT * FROM Autos WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteAufträge AS
	SELECT * FROM Aufträge WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteWerksaufträge AS
	SELECT WID, Name AS Werkname, AID, Status, Herstellungsbeginn, Herstellungsende
	FROM Werksaufträge JOIN Werke USING (WID) WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteBestellungen AS
	SELECT * FROM bestellt WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteLieferungen AS
	SELECT * FROM liefert WHERE Lieferdatum IS NOT NULL;



-- Manager können über diese Sichten Rückschlüsse auf Ausgaben bzw. Zeitvergeudung ziehen
--CREATE OR REPLACE VIEW Ausgaben AS
	-- Abweichungen der max preise von den tatsächlichen Preisen angeben -> aggregieren in analysefunktion
-- TODO: test spezialisierungen update personal
-- TODO: Fragen: Wo speichern wir den Mitarbeiter, der Herstellungsbeginn und -ende einscannt?
-- 	Er muss verantwortlich gemacht werden können.
CREATE OR REPLACE VIEW Zeitverzögerungen AS
	Select AID, Vorraussichtliches_Lieferdatum, Datum AS Eingangsdatum, Herstellungsbeginn, Herstellungsende, Lieferdatum
	FROM Aufträge JOIN Werksaufträge USING (AID) JOIN liefert USING (AID);
	-- Evt. noch MitarbeiterID aller zu jeder Phase verantwortlichen Mitarbeiter?
	-- Möglichst angeben wieviel Verzögerungen in jeder Phase der Abarbeitung entstanden sind und welcher Mitarbeiter gescannt hat
