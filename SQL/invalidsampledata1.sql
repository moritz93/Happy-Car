--ANM: PLZ mit 00 am Anfang ungültig
--INSERT INTO Personen VALUES (19, 'Gina', 'Wild', '66666', 'Puffotterstr.6','G-String','gina@youporn.com', 0190464646),
--			    (20, 'Günther', 'Kotz', '00123', 'Darmweg 1', 'Gammeltown', 'jfdioahf@nga.hdu', 3758910756),
--			    (21, 'Mustafa', 'Sandal', '12345', 'Rururustr.1', 'Rururustadt', 'hbvoa@bjspi.de', 3975057044209);
--ANM: INSERT in Werksarbeiter mit Wid=NULL ungültig
--INSERT INTO Werksarbeiter (Pid) VALUES (19);

--ANM: INSERT in Teilelagerarbeiter mit Wid=NULL ungültig
--INSERT INTO Mitarbeiter VALUES (21, '2013-07-07', 500);
--INSERT INTO Lagerarbeiter VALUES (21);
--INSERT INTO Teilelagerarbeiter (PID) VALUES (21);

--ANM: INSERT in LKW_fahrer mit führerscheindatum < 3 jahre ungültig
--INSERT INTO Mitarbeiter VALUES (20, '2013-08-08', 40000);
--INSERT INTO lkw_fahrer VALUES (20, '2011-10-30');

--ANM: INSERT in Mitarbeiter mit beschäftigungsbeginn in zukunft ungültig
--INSERT INTO Mitarbeiter VALUES (19, '2015-01-01', 100);

--ANM: Nach INSERT in liefert Status von Auto auf "Liefernd" setzen
--INSERT INTO liefert VALUES (0, 4, 2, 10, 0, '2016-01-01');
--DELETE FROM liefert WHERE kfz_id=4 AND mid=10 AND aid=0;

--ANM: Bei Großhändler: 0<=Rabatt<=100
--UPDATE Großhändler SET rabatt=150 WHERE gid=0;

--ANM: Bei Delete in bestellt insert into autoteile
DELETE FROM bestellt WHERE hid=0 AND wid=0 AND teiletypid=0 AND bestelldatum='2014-01-12';
