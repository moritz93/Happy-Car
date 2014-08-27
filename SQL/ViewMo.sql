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
		SELECT Aufträge.AID
		FROM Aufträge
		JOIN liefert
		ON Aufträge.AID = liefert.AID
		WHERE liefert.Lieferdatum IS NULL

	)
	SELECT AID AS "Auftragsnr." FROM offeneAufträge;