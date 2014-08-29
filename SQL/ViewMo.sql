SELECT Bezeichnung, count(*) AS "bereits verkauft"
FROM archivierteAufträge
JOIN Modelle
ON Modelle.Modell_ID = Aufträge.Modell_ID
GROUP BY Anzahl

