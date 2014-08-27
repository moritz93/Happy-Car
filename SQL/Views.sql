-- FORMAT: Je eine Sicht gefolgt von den auf sie bezogenen Regeln



-- Bietet Kundenname, Modellname, Vor. Lieferdatum, Anzahl, Preis und Auftragsnummer aller Aufträge einer Schnittstelle an
CREATE OR REPLACE VIEW Kundensicht AS
	WITH Kundeninfo AS
		(SELECT Vorname, Nachname, Aufträge.AID AS Auftrag1 FROM Aufträge JOIN Personen ON Aufträge.KundenID = Personen.PID),
	Modellname AS
		(SELECT Bezeichnung, Aufträge.AID AS Auftrag2 FROM Aufträge JOIN Modelle ON Aufträge.Modell_ID = Modelle.Modell_ID)
	SELECT Vorname, Nachname, Bezeichnung AS Modell, Vorraussichtliches_Lieferdatum, Anzahl, Preis, AID AS Auftragsnummer 
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
CREATE OR REPLACE RULE manufacturerCommandD AS ON DELETE TO Herstellerangebot
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
DO ALSO DELETE FROM produzieren WHERE TeiletypID = OLD.TeiletypID AND HID = OLD.Herstelleridentifikationsnummer 
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
UPDATE liefert SET Lieferdatum = now() WHERE liefert.KFZ_ID = OLD.Fahrgestellnummer_Ware AND liefert.AID = OLD.Auftragsnummer AND liefert.MID = OLD.FahrerID;

-- Zu diesem Zeitpunkt wird ebenfalls der Status jedes ausgelieferten Wagens auf 'ARCHIVIERT' gesetzt
-- Das führt ebenfalls zur Aufnahme des Wagens in den Autolager Index
CREATE OR REPLACE RULE scanDeliveryState AS ON UPDATE TO LKW_FahrerSicht
WHERE OLD.Fahrervorname = NEW.Fahrervorname AND OLD.Fahrernachnahme = NEW.Fahrernachname AND OLD.LKW_Nummer = NEW.LKW_Nummer
	AND OLD.Fahrgestellnummer_Ware = NEW.Fahrgestellnummer_Ware AND OLD.Auftragsnummer = NEW.Auftragsnummer AND OLD.FahrerID = NEW.FahrerID
UPDATE Autos SET Status = 'ARCHIVIERT' WHERE Autos.KFZ_ID = OLD.Fahrgestellnummer_Ware;



-- Personalmanagement wird über folgende Sichten realisiert:

-- Personal liefert einen Überblick über alle im Unternehmen beschäftigten Mitarbeiter, aber gestattet kein Einfügen eines neuen Mitarbeiters,
-- da alle Mitarbeiter über eine Spezialisierung verfügen müssen
CREATE OR REPLACE VIEW Personal AS
	SELECT PID AS Mitarbeiter_ID, Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr, Beschäftigungsbeginn, Gehalt, NULL AS Spezialisierung
	FROM Personen JOIN Mitarbeiter ON Personen.PID = Mitarbeiter.PID;

CREATE OR REPLACE RULE selectAutolager AS ON SELECT TO Personal AS SELECT Mitarbeiter_ID, Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr, Beschäftigungsbeginn, Gehalt, CASE WHEN  FROM (Personen JOIN Mitarbeiter ON Personen.PID=Mitarbeiter.MID)
	

CREATE OR REPLACE RULE employeeCommandI AS ON INSERT TO Personal
DO INSTEAD NOTHING;
CREATE OR REPLACE RULE employeeCommandU AS ON UPDATE TO Personal
DO INSTEAD NOTHING;
CREATE OR REPLACE RULE employeeCommand


-- Personalmanagement -> Sicht die alle Spezialisierungen konsolidiert
-- Für jedes Archiv eine View -> bestellungen
-- Sicht für ingenierue machen, die neue teile einfügen können
-- Sicht für Verwaltungsangestellte


-- Sicht auf alle sich in Produktion befindender Aufträge bzw. solcher die in den Werken momentan assembliert werden
CREATE OR REPLACE VIEW Produktion AS
	SELECT WID, AID, Status FROM Werksaufträge GROUP BY WID HAVING Status = 'IN_BEARBEITUNG';

-- TODO: bei rules auf timestamps achten