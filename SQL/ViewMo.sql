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



-- calculate price for inserted order
CREATE FUNCTION calculatePrice() RETURNS TRIGGER AS
	$$
	DECLARE
	rabat integer;
	BEGIN
	rabat := 
		SELECT KundenID FROM NEW
	
	END; $$ LANGUAGE plpgsql;
	
CREATE TRIGGER calculatePrice AFTER INSERT ON Aufträge FOR EACH ROW EXECUTE PROCEDURE calculatePrice();