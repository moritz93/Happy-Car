--Transaktion, die einen fertigen Auftrag einfügt.
BEGIN;
INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (1,5, 1, 3);
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
INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (1,6, 1, 3);
INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (2,7, 1, 3);
INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (3,8, 1, 3);
INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (4,8, 1, 3);
COMMIT;
