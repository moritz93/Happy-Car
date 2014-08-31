-- Analysefunktionen

--1: Die Anzahl aller bereits verkauften Autos absteigend sortiert.
SELECT Modelle.Modell_ID, Bezeichnung, sum(archivierteAufträge.Anzahl) AS "bereits verkauft"
FROM archivierteAufträge
JOIN Modelle
ON Modelle.Modell_ID = archivierteAufträge.Modell_ID
GROUP BY Modelle.Modell_ID
ORDER BY "bereits verkauft" DESC;


--2: Alle Autoteiltypen mit Anzahl der Hersteller, Mindestpreis und den zu diesem Preis produzierenden Hersteller
SELECT tmp1.TeiletypId, Bezeichnung,  Herstelleranzahl, Mindestpreis, Herstellerid, Firmenname
FROM
(
SELECT TeiletypId, Bezeichnung, count(*) AS Herstelleranzahl, min(Preis) AS Mindestpreis
FROM herstellerangebot
GROUP BY teiletypid, Bezeichnung
) AS tmp1
JOIN

(
SELECT TeiletypID, Herstellerid, Firmenname, Preis
FROM herstellerangebot
) AS tmp2

ON tmp1.teiletypid = tmp2.teiletypid AND mindestpreis = preis
ORDER BY tmp1.Teiletypid;


--3: Produktivität der Werke beim Bearbeitung der Werksaufträge hinsichtlich der gebauten Autos pro Zeit
WITH tmp AS (
SELECT auftragsnummer AS aid, anzahl, modell
FROM kundensicht
)


SELECT WID, avg(tmp2.Effizienz) AS "durchnittl. Werksperformance"
FROM
(
SELECT wid, aid, age(herstellungsende, herstellungsbeginn) AS zeit, anzahl, modell, Anzahl /  (SELECT (EXTRACT(epoch FROM age(herstellungsende, herstellungsbeginn))/3600 ):: integer) AS Effizienz
FROM archivierteWerksaufträge
JOIN tmp
USING (aid)
ORDER BY Effizienz DESC
) AS tmp2
GROUP BY WID


--4. Zeigt an, wieviele der LKWs, die ein Fahrer gefahren hat bereits geschrottet sind.
SELECT MID, count(*) FROM liefert GROUP BY MID, LKW_ID HAVING (LKW_ID IS NULL);

--5. Zeigt die Großhändler an, die einen Rabatt haben und was deren teuerste Bestellung bei uns war.
SELECT count(*) AS "Anzahl Einkäufe", Rabatt, Firmenname, max(Preis) AS "teuerster Einkauf", GID FROM ((Kontaktpersonen JOIN (SELECT KundenID AS PID, Preis FROM Aufträge) AS tmp USING (PID)) JOIN Großhändler USING (GID)) GROUP BY GID, Rabatt, Firmenname HAVING Rabatt>0;
