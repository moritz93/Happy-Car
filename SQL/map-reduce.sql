--Realisiert die 5. Analyse Abfrage als Map-Reduce Funktion.
--SELECT count(*) AS "Anzahl Einkäufe", Rabatt, Firmenname, max(Preis) AS "teuerster Einkauf", GID FROM ((Kontaktpersonen JOIN (SELECT KundenID AS PID, Preis FROM Aufträge) AS tmp USING (PID)) JOIN Großhändler USING (GID)) GROUP BY GID, Rabatt, Firmenname HAVING Rabatt>0;

CREATE OR REPLACE FUNCTION map(integer) RETURNS TABLE (GID integer,Preis numeric(10,2)) AS
	$$
	BEGIN
	IF((SELECT Rabatt FROM Großhändler WHERE Großhändler.GID=(SELECT Kontaktpersonen.GID FROM Kontaktpersonen WHERE PID=$1))>0) THEN
		RETURN QUERY (SELECT Großhändler.GID, Aufträge.Preis FROM ((Kontaktpersonen JOIN Großhändler USING (GID)) JOIN Aufträge ON KundenID=PID));
	END IF;
	END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reduce(integer, numeric ARRAY) RETURNS TABLE("Anzahl Käufe" integer, Rabatt integer, Firmenname varchar, "teuerster Einkauf" numeric(10,2), GID integer) AS
	$$
	DECLARE 
	maxPrice numeric(10,2);
	price numeric(10,2);
	counter integer;
	discount integer;
	buisnessname varchar;
	BEGIN
	counter=0;
	maxPrice=-42;
	FOREACH price IN ARRAY $2
	LOOP
		counter=counter+1;
		IF(price>maxPrice)THEN
			maxPrice=price;
		END IF;
	END LOOP;
	buisnessname=(SELECT Großhändler.Firmenname FROM Großhändler WHERE Großhändler.GID=$1);
	discount=(SELECT Großhändler.Rabatt FROM Großhändler WHERE Großhändler.GID=$1);
	RETURN QUERY (SELECT counter, discount, buisnessname, maxPrice, $1);
	END; $$ LANGUAGE plpgsql;

--Ausgeführt wird das Statement, indem man erst Map auf eine GID aufruft:
--SELECT * FROM map(1);
--und dann reduce auf einen Ikey(GID) und ein Array von Ivalues aufruft:
--SELECT * FROM reduce(1,  ARRAY[37998.10,1899905.00,18999050.00]);

--Beispieldaten für Map-Reduce:
--INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (1, 100, 1, 3);
--INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (1, 1000, 1, 3);
--INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (1, 10000, 1, 3);
--INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (1, 100000, 1, 3);
