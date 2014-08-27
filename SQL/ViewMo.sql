-- 1
-- Noch ausstehende Aufträge, die noch nicht an den Kunden geliefert worden sind.
-- Ausgegeben wird AID, eingeganenAm, KID, Kundenname, ggf. Großhändler, vorraussichtliches Lieferdatum, ggf. Status

--SELECT AID, Datum AS "eingegangen am", Vorraussichtliches_Lieferdatum AS "vorrauss. Lieferung", Nachname, Vorname
--SELECT *
--FROM Aufträge
--JOIN (
--	SELECT Lieferdatum
--	FROM liefert
--	WHERE Lieferdatum IS NULL AND Aufträge.AID = liefert.AID
 --    ) AS notDeliveredYet


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