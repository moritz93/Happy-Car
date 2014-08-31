INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (1, 3, 1, 3);
UPDATE bestellt SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
UPDATE Werksaufträge SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
DELETE FROM liefert WHERE AID=(SELECT currval('Aufträge_aid_seq'));

INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES (1, 4, 1, 3);
UPDATE bestellt SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
UPDATE Werksaufträge SET Status='ARCHIVIERT' WHERE AID=(SELECT currval('Aufträge_aid_seq'));
DELETE FROM liefert WHERE AID=(SELECT currval('Aufträge_aid_seq'));
