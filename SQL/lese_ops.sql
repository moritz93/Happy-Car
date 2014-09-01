--Zeige alle offenen Aufträge, die schon mind. 4 Tage offen sind
SELECT * FROM ((SELECT "Auftragsnr." AS AID FROM offene_Aufträge) AS tmp JOIN admin_Aufträge USING (AID)) WHERE Datum<(now()-interval '4 days');
--Zeige alle Aufträge von Personen namens Michael Müller
SELECT * FROM Kundensicht WHERE Vorname='Michael' AND Nachname='Müller';
--Zeige zu einem zufälligen Hersteller alle Teileangebote an.
SELECT * FROM Herstellerangebot WHERE HerstellerID=(SELECT HID FROM admin_Hersteller LIMIT 1);
--Zeige alle Mitarbeiter, die LKW_Fahrer sind
SELECT * FROM Personal WHERE Spezialisierung='LKW FAHRER';
--Zeige alle Motoren, die in einem Modell verbaut sind
SELECT * FROM IngenieursichtMotoren WHERE TeiletypID IN (SELECT TeiletypID FROM produzieren);
--Zeige alle Zeitverzögerten Aufträge an
SELECT * FROM Zeitverzögerungen WHERE (vorraussichtliches_Lieferdatum<lieferdatum);
--Zeige alle Aufträge an, bei denen die Produktion länger als 10 Tage gedauert hat
SELECT * FROM Zeitverzögerungen WHERE (Herstellungsende-Herstellungsbeginn)>10;
--Zeige alle Modelle mit Teilen, die schonmal verkauft wurden.
SELECT Modell_id, TeiletypID, ModellteileSicht.anzahl FROM ModellteileSicht JOIN admin_Aufträge USING (Modell_ID);
--Zeige aktuelle Produktion
SELECT * FROM Produktion;
--Zeige Kunden
SELECT * FROM VerwaltungKundenaufnahme;
