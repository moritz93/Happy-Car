SELECT Bezeichnung, sum(Modelle.Anzahl) AS "bereits verkauft"
FROM archivierteAufträge
JOIN Modelle
ON Modelle.Modell_ID = Aufträge.Modell_ID
GROUP BY Modell_ID

