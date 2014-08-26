-- Bietet Kundenname, Modellname, Vor. Lieferdatum, Anzahl, Preis und Auftragsnummer aller Aufträge einer Schnittstelle an
CREATE OR REPLACE VIEW Kundensicht AS
	WITH Kundeninfo AS
			SELECT Name, Aufträge.AID AS Auftrag1 FROM Aufträge JOIN Kunden ON Aufträge.KundenID = Kunden.PID
	Modellname AS
			SELECT Bezeichnung, Aufträge.AID AS Auftrag2 FROM Aufträge JOIN Modelle ON Aufträge.Modell_ID = Modelle.Modell_ID WHERE AID = $1
	SELECT Name AS Kunden_Name, Bezeichnung AS Modell, Vorraussichtliches_Lieferdatum, Anzahl, Preis, AID AS Auftragsnummer 
	FROM (SELECT * FROM Kundeninfo JOIN Modellname ON Auftrag1 = Auftrag2) AS tmp JOIN Aufträge on AID = Auftrag1;
