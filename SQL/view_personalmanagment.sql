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

--INSERT INTO Personal (Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr, Beschäftigungsbeginn, Gehalt, arbeitet_in, Führerscheindatum, Spezialisierung)
--	      VALUES ('Ein', 'kleiner', '64822', 'Hauptstr.1', 'MyTown', 'oihagpsn@igao.de', 08504257084, now(), 5000, 1, NULL, 'TEILELAGERARBEITER');

--SELECT * FROM Personal;

	