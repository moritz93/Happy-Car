--Transaktion, die einen Auftrag der aus mehreren Modellen besteht einfügt.
BEGIN;
INSERT INTO VerwaltungAuftragssicht (Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (1, 1, 4, 8);
INSERT INTO VerwaltungAuftragssicht (Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (2, 1, 4, 8);
INSERT INTO VerwaltungAuftragssicht (Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (3, 1, 4, 8);
INSERT INTO VerwaltungAuftragssicht (Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (4, 1, 4, 8);
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
DO $$
DECLARE
großh integer;
person integer;
BEGIN
INSERT INTO admin_Großhändler (Firmenname, Straße, PLZ, Ort, Rabatt) VALUES ('Fuego Corp', 'IobgabguodeStr. 19', '00000', 'Somewhere', 9);
großh=lastVal();
INSERT INTO admin_Personen (Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr) VALUES ('Thomas', 'Müller', '12345', 'Gortortstr. 1', 'Tuzfy', 'Trererestr@gmx.de', 0863493738);
person=lastVal();
INSERT INTO admin_Kunden VALUES (person, 40000);
INSERT INTO admin_Kontaktpersonen (PID,GID) VALUES (person,großh);
END; $$ LANGUAGE plpgsql;
COMMIT;

CREATE OR REPLACE VIEW admin_Türen AS
	SELECT * FROM Türen;

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
teil1=lastVal();
INSERT INTO admin_Autoteiltypen (maxpreis, Bezeichnung) VALUES ('156', 'Oplelj');
teil2=lastVal();
INSERT INTO admin_Autoteiltypen (maxpreis, Bezeichnung) VALUES ('8897', 'Hungar');
teil3=lastVal();
INSERT INTO admin_Autoteiltypen (maxpreis, Bezeichnung) VALUES ('81', 'Afhgoae');
teil4=lastVal();

INSERT INTO admin_produzieren (teil1, 1, '799.99');
INSERT INTO admin_produzieren (teil2, 1, '99.99');
INSERT INTO admin_produzieren (teil3, 1, '7889.99');
INSERT INTO admin_produzieren (teil4, 1, '79.99');


INSERT INTO admin_Motoren VALUES (teil1, 188, 4679,  1, 'Elektro');
INSERT INTO admin_Türen VALUES (teil2, 'Burgunderrot', 'FLÜGELTÜR');
INSERT INTO admin_Reifen VALUES (teil4, 'Schwarz', 14, 'Chrom');
INSERT INTO admin_Karosserien VALUES (teil3, 'Pink', 'Plastik', 654, 170, 300);
INSERT INTO admin_Modelle (Preis, Bezeichnung) VALUES (15149.99, 'El Aridnai');
car=lastVal();
INSERT INTO admin_Modellteile VALUES (car, teil1 , 1);
INSERT INTO admin_Modellteile VALUES (car, teil2, 5);
INSERT INTO admin_Modellteile VALUES (car, teil3, 1);
INSERT INTO admin_Modellteile VALUES (car, teil4, 4);
END; $$ LANGUAGE plpgsql;
COMMIT;


