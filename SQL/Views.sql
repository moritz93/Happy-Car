-- FORMAT: Je eine Sicht gefolgt von den auf sie bezogenen Regeln



-- Bietet Kundenname, Modellname, Vor. Lieferdatum, Anzahl, Preis und Auftragsnummer aller Aufträge einer Schnittstelle an
CREATE OR REPLACE VIEW Kundensicht AS
	WITH Kundeninfo AS
		(SELECT Vorname, Nachname, Aufträge.KundenID AS KundenID, Aufträge.AID AS Auftrag1 FROM Aufträge JOIN Personen ON Aufträge.KundenID = Personen.PID),
	Modellname AS
		(SELECT Bezeichnung, Aufträge.AID AS Auftrag2 FROM Aufträge JOIN Modelle ON Aufträge.Modell_ID = Modelle.Modell_ID)
	SELECT Vorname, Nachname, KundenID, Bezeichnung AS Modell, Vorraussichtliches_Lieferdatum, Datum AS Auftrag_erteilt_am, Anzahl, Preis, AID AS Auftragsnummer 
	FROM (SELECT * FROM Kundeninfo JOIN Modellname ON Auftrag1 = Auftrag2) AS tmp JOIN Aufträge on AID = Auftrag1;



-- Erlaubt einem Hersteller sein Teileangebot einzusehen und ggf. anzupassen
CREATE OR REPLACE VIEW Herstellerangebot AS
	WITH Herstellerteile AS
		(SELECT Hersteller.HID AS HID, Firmennamen, TeiletypID, Preis, Zeit FROM Hersteller JOIN produzieren ON Hersteller.HID = produzieren.HID)
	SELECT Firmennamen, HID AS Herstelleridentifikationsnummer, TeiletypID, Preis, Zeit FROM Herstellerteile;

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
WHERE NEW.TeiletypID = OLD.TeiletypID DO ALSO UPDATE produzieren
	SET HID = NEW.Herstelleridentifikationsnummer, Preis = NEW.Preis, Zeit = NEW.Zeit
	WHERE TeiletypID = OLD.TeiletypID AND HID = OLD.Herstelleridentifikationsnummer;

CREATE OR REPLACE RULE manufacturerDeletePartInInventory AS ON DELETE TO Herstellerangebot
DO INSTEAD DELETE FROM produzieren WHERE TeiletypID = OLD.TeiletypID AND HID = OLD.Herstelleridentifikationsnummer 
	AND Preis = OLD.Preis AND Zeit = OLD.Zeit;



-- Zeigt die aktuellen Bestellungen einem Hersteller an (nicht modifizierbar)
CREATE OR REPLACE VIEW Herstellerbestellungen AS
	SELECT Firmennamen, Hersteller.HID AS Herstelleridentifikationsnummer, BID AS Bestellungsnummer, Status AS Bestellungsstatus, 
	bestellt.TeiletypID AS TeiletypID, Bezeichnung AS Teilbezeichnung
	FROM Hersteller JOIN bestellt ON Hersteller.HID = bestellt.HID JOIN Autoteiltypen ON bestellt.TeiletypID = Autoteiltypen.TeiletypID;



-- Ermöglicht einem Teilelagerarbeiter das Einscannen eingegangener Teilelieferungen
CREATE OR REPLACE VIEW Teilelagerarbeitersicht AS
	SELECT BID AS BestellungsID FROM bestellt;

CREATE OR REPLACE RULE scanCommandU AS ON UPDATE TO Teilelagerarbeitersicht
DO INSTEAD NOTHING;

CREATE OR REPLACE RULE scanIn AS ON UPDATE TO Teilelagerarbeitersicht
DO ALSO UPDATE bestellt SET Status = 'ARCHIVIERT' WHERE BID = OLD.BestellungsID;



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
DO ALSO UPDATE Werksaufträge SET Status = 'ARCHIVIERT' WHERE WID = OLD.Werknummer AND AID = OLD.Auftragsnummer;



-- Die Informationen, die ein LKW Fahrer zur Auslieferung benötigt
CREATE OR REPLACE VIEW LKW_FahrerSicht AS
	SELECT Vorname AS Fahrervorname, Name AS Fahrernachname, MID AS FahrerID, liefert.LKW_ID AS LKW_Nummer, Autos.KFZ_ID AS Fahrgestellnummer_Ware,
	liefert.AID AS Auftragsnummer, Aufträge.Status AS Auftragsstatus
	FROM liefert JOIN Personen ON liefert.MID = Personen.PID JOIN Autos ON liefert.KFZ_ID = Autos.KFZ_ID 
		JOIN Aufträge ON liefert.AID = Aufträge.AID;

-- LKW Fahrer dürfen nur den Status auf 'ARCHIVIERT' setzten
CREATE OR REPLACE RULE driverCommandU AS ON UPDATE TO LKW_FahrerSicht
DO INSTEAD NOTHING;

-- Setzt Lieferdatum auf aktuellen Zeitpunkt sobald die bestellten Autos beim Kunden ausgeliefert werden
-- Hier durch wird die Lieferung im entsprechenden Index aufgenommen
CREATE OR REPLACE RULE scanDeliveryDate AS ON UPDATE TO LKW_FahrerSicht
WHERE OLD.Fahrervorname = NEW.Fahrervorname AND OLD.Fahrernachnahme = NEW.Fahrernachname AND OLD.LKW_Nummer = NEW.LKW_Nummer
	AND OLD.Fahrgestellnummer_Ware = NEW.Fahrgestellnummer_Ware AND OLD.Auftragsnummer = NEW.Auftragsnummer AND OLD.FahrerID = NEW.FahrerID
DO ALSO UPDATE liefert SET Lieferdatum = now() WHERE liefert.KFZ_ID = OLD.Fahrgestellnummer_Ware AND liefert.AID = OLD.Auftragsnummer AND liefert.MID = OLD.FahrerID;

-- Zu diesem Zeitpunkt wird ebenfalls der Status jedes ausgelieferten Wagens auf 'ARCHIVIERT' gesetzt
-- Das führt ebenfalls zur Aufnahme des Wagens in den Autolager Index
CREATE OR REPLACE RULE scanDeliveryState AS ON UPDATE TO LKW_FahrerSicht
WHERE OLD.Fahrervorname = NEW.Fahrervorname AND OLD.Fahrernachnahme = NEW.Fahrernachname AND OLD.LKW_Nummer = NEW.LKW_Nummer
	AND OLD.Fahrgestellnummer_Ware = NEW.Fahrgestellnummer_Ware AND OLD.Auftragsnummer = NEW.Auftragsnummer AND OLD.FahrerID = NEW.FahrerID
DO ALSO UPDATE Autos SET Status = 'ARCHIVIERT' WHERE Autos.KFZ_ID = OLD.Fahrgestellnummer_Ware;



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
DO INSTEAD INSERT INTO Aufträge VALUES (NEW.Auftragsnummer, NEW.Preis, NEW.Vorraussichtliches_Lieferdatum, NEW.Modell_ID, NEW.Anzahl, NEW.Datum, NEW.KundenID, NEW.MitarbeiterID);



-- Sicht auf alle sich in Produktion befindender Aufträge bzw. solcher die in den Werken momentan assembliert werden
CREATE OR REPLACE VIEW Produktion AS
	SELECT WID, AID, Status FROM Werksaufträge GROUP BY WID HAVING Status = 'IN_BEARBEITUNG';



-- Über folgende Sichten können die Archive eingesehen werden:
CREATE OR REPLACE VIEW archivierteAutos AS
	SELECT * FROM Autos WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteAufträge AS
	SELECT * FROM Aufträge WHERE Lieferdatum IS NOT NULL;

CREATE OR REPLACE VIEW archivierteWerksaufträge AS
	SELECT * FROM Werksaufträge WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteBestellungen AS
	SELECT * FROM bestellt WHERE Status = 'ARCHIVIERT';

CREATE OR REPLACE VIEW archivierteLieferungen AS
	SELECT * FROM liefert WHERE Lieferdatum IS NOT NULL;



-- Personalmanagement wird über folgende Sichten realisiert:

-- Personal liefert einen Überblick über alle im Unternehmen beschäftigten Mitarbeiter, aber gestattet kein Einfügen eines neuen Mitarbeiters,
CREATE OR REPLACE VIEW Personal AS
	SELECT  Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr, Beschäftigungsbeginn, Gehalt, (date '01-01-2014') AS Führerscheindatum, (integer '13') AS arbeitet_in ,(varchar '') AS Spezialisierung
	FROM (Personen JOIN Mitarbeiter ON Personen.PID = Mitarbeiter.PID);

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
	INSERT INTO Mitarbeiter (PID, Beschäftigungsbeginn, Gehalt) VALUES (thisID, CURRENT_DATE, NEW.Gehalt);
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
			INSERT INTO Werksarbeiter VALUES (thisID);
		WHEN 'VERWALTUNGSANGESTELLTE' THEN
			INSERT INTO Verwaltungsangestellte VALUES (thisID);
		WHEN 'LAGERARBEITER' THEN
			INSERT INTO Lagerarbeiter VALUES (thisID);
		WHEN 'MITARBEITER' THEN
			RETURN NEW;
		ELSE
			RAISE EXCEPTION 'Ungültige Spezialisierung: %',NEW.Spezialisierung;
	END CASE;
	RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onInsertInPersonal INSTEAD OF INSERT ON Personal FOR EACH ROW EXECUTE PROCEDURE insertInPersonal();


-- Ingenieure können über diese Sicht neue Teiletypen einführen
CREATE OR REPLACE VIEW Ingenieursicht AS
	SELECT Bezeichnung, TeiletypID, maxPreis, Teiletyp IN ""
	FROM Autoteiltypen NATURAL JOIN Motoren...



-- Manager können über diese Sichten Rückschlüsse auf Ausgaben bzw. Zeitvergeudung ziehen
CREATE OR REPLACE VIEW Ausgaben AS
	-- Abweichungen der max preise von den tatsächlichen Preisen angeben -> aggregieren in analysefunktion

CREATE OR REPLACE VIEW Zeitverzögerungen AS
	-- Möglichst angeben wieviel Verzögerungen in jeder Phase der Abarbeitung entstanden sind und welcher Mitarbeiter gescannt hat

	
-- Personalmanagement -> Sicht die alle Spezialisierungen konsolidiert

-- TODO: bei rules auf timestamps achten
-- Sicht für offene Aufträge
-- TODO: Ausnahmen werfen
-- TODO: Überall wo etwas mit Aufträgen gemacht wird darauf achten dass auch ein Auftragsstatus übergeben wird




-- Personal liefert einen Überblick über alle im Unternehmen beschäftigten Mitarbeiter, sowie ihre Spezialisierung und deren Attribute, und dient der Umsetzung des Personalmanagements
-- Über die Select Regel wird die Spezialisierung automatisch ermittelt und ausgegeben
-- Das Personalmangement darf Mitarbeiter einstellen und entlassen, sowie ihre Daten anpassen
CREATE OR REPLACE VIEW Personal AS
	SELECT  Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr, Beschäftigungsbeginn, Gehalt, (date '01-01-2014') AS Führerscheindatum, (integer '13') AS arbeitet_in,
	(varchar '') AS Spezialisierung FROM (Personen JOIN Mitarbeiter ON Personen.PID = Mitarbeiter.PID);

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
	INSERT INTO Mitarbeiter (PID, Beschäftigungsbeginn, Gehalt) VALUES (thisID, CURRENT_DATE, NEW.Gehalt);
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
			INSERT INTO Werksarbeiter VALUES (thisID);
		WHEN 'VERWALTUNGSANGESTELLTE' THEN
			INSERT INTO Verwaltungsangestellte VALUES (thisID);
		WHEN 'LAGERARBEITER' THEN
			INSERT INTO Lagerarbeiter VALUES (thisID);
		WHEN 'MITARBEITER' THEN
			RETURN NEW;
		ELSE
			RAISE EXCEPTION 'Ungültige Spezialisierung: %',NEW.Spezialisierung;
	END CASE;
	RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onInsertInPersonal INSTEAD OF INSERT ON Personal FOR EACH ROW EXECUTE PROCEDURE insertInPersonal();

CREATE OR REPLACE FUNCTION updatePersonal() RETURNS TRIGGER AS
	$$
	BEGIN
	UPDATE Personen SET Vorname = NEW.Vorname, Nachname = NEW.Nachname, PLZ = NEW.PLZ, Straße = NEW.Straße, Wohnort = NEW.Wohnort, Email = NEW.Email, TelNr = NEW.TelNr
	WHERE PID = NEW.PID;
	-- TODO: UPdate vervollständigen, dann delete machen
	INSERT INTO Mitarbeiter (PID, Beschäftigungsbeginn, Gehalt) VALUES (thisID, CURRENT_DATE, NEW.Gehalt);
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
			INSERT INTO Werksarbeiter VALUES (thisID);
		WHEN 'VERWALTUNGSANGESTELLTE' THEN
			INSERT INTO Verwaltungsangestellte VALUES (thisID);
		WHEN 'LAGERARBEITER' THEN
			INSERT INTO Lagerarbeiter VALUES (thisID);
		WHEN 'MITARBEITER' THEN
			RETURN NEW;
		ELSE
			RAISE EXCEPTION 'Ungültige Spezialisierung: %',NEW.Spezialisierung;
	END CASE;
	RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onInsertInPersonal INSTEAD OF INSERT ON Personal FOR EACH ROW EXECUTE PROCEDURE insertInPersonal();