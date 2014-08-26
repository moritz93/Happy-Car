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



-- Ermöglicht einem Lagerarbeiter das einscannen eingegangener Teilelieferungen
CREATE OR REPLACE VIEW LieferungScannen AS
	SELECT BID AS BestellungsID FROM bestellt;

-- Notwendig da laut Postgres Doku von CREATE RULE:
-- "There is a catch if you try to use conditional rules for view updates: 
-- there must be an unconditional INSTEAD rule for each action you wish to allow on the view."
CREATE OR REPLACE RULE scanCommandU AS ON UPDATE TO LieferungScannen
DO INSTEAD NOTHING;

CREATE OR REPLACE RULE scanIn AS ON UPDATE TO LieferungScannen
DO ALSO UPDATE bestellt SET Status = 'ARCHIVIERT' WHERE BID = OLD.BestellungsID;

-- Personalmanagement -> Sicht die alle Spezialisierungen konsolidiert
-- Für jedes Archiv eine View -> bestellungen
