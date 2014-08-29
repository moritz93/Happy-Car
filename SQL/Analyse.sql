-- Analysefunktionen

--1: Die Anzahl aller bereits verkauften Autos absteigend sortiert.
SELECT Modelle.Modell_ID, Bezeichnung, sum(archivierteAufträge.Anzahl) AS "bereits verkauft"
FROM archivierteAufträge
JOIN Modelle
ON Modelle.Modell_ID = archivierteAufträge.Modell_ID
GROUP BY Modelle.Modell_ID
ORDER BY "bereits verkauft" DESC




