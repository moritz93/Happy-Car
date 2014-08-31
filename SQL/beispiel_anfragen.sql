INSERT INTO admin_Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (1, 3, 1, 3);
UPDATE admin_bestellt SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
UPDATE admin_Werksaufträge SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
DELETE FROM admin_liefert WHERE AID=(SELECT currval('Aufträge_aid_seq'));

INSERT INTO admin_Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (1, 4, 1, 3);
UPDATE admin_bestellt SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
UPDATE admin_Werksaufträge SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
DELETE FROM admin_liefert WHERE AID=(SELECT currval('Aufträge_aid_seq'));
