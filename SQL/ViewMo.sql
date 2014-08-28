 CREATE OR REPLACE VIEW offene_Aufträge AS
	WITH offeneAufträge AS
	(
	SELECT *
	FROM    (	
		SELECT Aufträge.AID, KundenID, Vorraussichtliches_Lieferdatum
		FROM Aufträge
		JOIN Kunden
		ON Aufträge.KundenID = Kunden.PID
		WHERE Aufträge.status = 'WARTEND'
		) AS auftragT
	JOIN Personen
	ON auftragT.KundenID = Personen.PID

	)
	SELECT AID AS "Auftragsnr.", vorraussichtliches_lieferdatum AS "Vorrauss. Lieferung" , Vorname AS "Kundenvorname", Nachname AS "Kundenname", TelNr AS "Tel." FROM offeneAufträge;



