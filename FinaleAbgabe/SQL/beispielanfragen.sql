

-- Änderungsoperationen


INSERT INTO admin_Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (1, 3, 7, 3);
UPDATE admin_bestellt SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
UPDATE admin_Werksaufträge SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
DELETE FROM admin_liefert WHERE AID=(SELECT currval('Aufträge_aid_seq'));

INSERT INTO admin_Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (1, 4, 7, 3);
UPDATE admin_bestellt SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
UPDATE admin_Werksaufträge SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
DELETE FROM admin_liefert WHERE AID=(SELECT currval('Aufträge_aid_seq'));


--Transaktion, die einen fertigen Auftrag einfügt.
BEGIN;
INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (1,5, 7, 3);
UPDATE bestellt SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
UPDATE Werksaufträge SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
DELETE FROM liefert WHERE AID=(SELECT currval('Aufträge_aid_seq'));
COMMIT;

--Transaktion, die einen archivierten Auftrag löscht.
BEGIN;
DELETE FROM admin_Autoteile WHERE AID=1;
DELETE FROM admin_bestellt WHERE AID=1;
DELETE FROM admin_liefert WHERE AID=1;
DELETE FROM admin_Werksaufträge WHERE AID=1;
DELETE FROM admin_Aufträge WHERE AID=1;
COMMIT;

--Transaktion, die einen Großhändler mit Kontaktperson einfügt.
BEGIN;
INSERT INTO admin_Großhändler (Firmenname, Straße, PLZ, Ort, Rabatt) VALUES ('Fuego Corp', 'IobgabguodeStr. 19', '00000', 'Somewhere', 9);
INSERT INTO admin_Personen (Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr) VALUES ('Thomas', 'Müller', '12345', 'Gortortstr. 1', 'Tuzfy', 'Trererestr@gmx.de', 0863493738);
INSERT INTO Kunden VALUES ((SELECT currval('personen_pid_seq')), 40000);
INSERT INTO admin_Kontaktpersonen (PID,GID) VALUES ((SELECT currval('personen_pid_seq')),currval('großhändler_gid_seq'));
COMMIT;

--Transaktion, die ein neues Modell mit Autoteiltypen einfügt.
BEGIN;
DO $$
DECLARE
teil1 integer;
teil2 integer;
teil3 integer;
teil4 integer;
car integer;
BEGIN
INSERT INTO admin_Autoteiltypen (maxpreis, Bezeichnung) VALUES ('888.99', 'Yufeka');
teil1=currval('autoteiltypen_teiletypid_seq');
INSERT INTO admin_Autoteiltypen (maxpreis, Bezeichnung) VALUES ('156', 'Oplelj');
teil2=currval('autoteiltypen_teiletypid_seq');
INSERT INTO admin_Autoteiltypen (maxpreis, Bezeichnung) VALUES ('8897', 'Hungar');
teil3=currval('autoteiltypen_teiletypid_seq');
INSERT INTO admin_Autoteiltypen (maxpreis, Bezeichnung) VALUES ('81', 'Afhgoae');
teil4=currval('autoteiltypen_teiletypid_seq');

INSERT INTO admin_produzieren VALUES (teil1, 1, '799.99', 5);
INSERT INTO admin_produzieren VALUES (teil2, 1, '99.99', 6);
INSERT INTO admin_produzieren VALUES (teil3, 1, '7889.99', 7);
INSERT INTO admin_produzieren VALUES (teil4, 1, '79.99', 8);


INSERT INTO admin_Motoren VALUES (teil1, 188, 4679,  1, 'Elektro');
INSERT INTO admin_Türen VALUES (teil2, 'Burgunderrot', 'FLÜGELTÜR');
INSERT INTO admin_Reifen VALUES (teil4, 'Schwarz', 14, 'Chrom');
INSERT INTO admin_Karosserien VALUES (teil3, 'Pink', 'Plastik', 654, 170, 300);
INSERT INTO admin_Modelle (Preis, Bezeichnung) VALUES (15149.99, 'El Aridnai');
car=currval('modelle_modell_id_seq');
INSERT INTO admin_Modellteile VALUES (car, teil1 , 1);
INSERT INTO admin_Modellteile VALUES (car, teil2, 5);
INSERT INTO admin_Modellteile VALUES (car, teil3, 1);
INSERT INTO admin_Modellteile VALUES (car, teil4, 4);
END; $$ LANGUAGE plpgsql;
COMMIT;

--Transaktion, die einen Auftrag mit mehrern Modellen in das System einfügt.
BEGIN;
INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (1,6, 7, 3);
INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (2,7, 7, 3);
INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (3,8, 7, 3);
INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (4,8, 7, 3);
COMMIT;

---------------------------------------------------------


-- Leseoperationen

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

---------------------------------------------------------


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
SELECT wid, aid, age(herstellungsende, herstellungsbeginn) AS zeit, anzahl, modell, Anzahl /  1 + (SELECT (EXTRACT(epoch FROM age(herstellungsende, herstellungsbeginn))/3600 ):: integer) AS Effizienz
FROM archivierteWerksaufträge
JOIN tmp
USING (aid)
ORDER BY Effizienz DESC
) AS tmp2
GROUP BY WID;


--4. Zeigt an, wieviele der LKWs, die ein Fahrer gefahren hat bereits geschrottet sind.
SELECT MID, count(*)
FROM liefert
GROUP BY MID, LKW_ID
HAVING (LKW_ID IS NULL);


--5. Zeigt die Großhändler an, die einen Rabatt haben und was deren teuerste Bestellung bei uns war.
SELECT count(*) AS "Anzahl Einkäufe", Rabatt, Firmenname, max(Preis) AS "teuerster Einkauf", GID
FROM ((Kontaktpersonen
	JOIN (SELECT KundenID AS PID, Preis FROM Aufträge) AS tmp USING (PID))
	JOIN Großhändler USING (GID)) 
GROUP BY GID, Rabatt, Firmenname
HAVING Rabatt>0;

---------------------------------------------------------


-- MapReduce

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

