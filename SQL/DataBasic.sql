INSERT INTO Personen (Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr) VALUES 
	('Peter', 'Müller', '66740', 'Hauptstr.1', 'Saarlouis', 'Peter.Müller@web.de', 0683100000),
	('Hans Adolf', 'Bibelroy', '11111', 'Einsstr. 11', 'Einsstadt', 'Hans_Adolf@somepage.com', 11111111111),
	('Sandra', 'Schmidt', '12487', 'Abram-Joffe-Straße 3', 'Berlin', 'S.Schmidt@joadkhgfa89.to', 017200011100),
	('Hermann', 'Buchmann', '01222', 'Straße 42', 'Stadt', 'buchmann@verwaltung.de', 028409374),
	('Gus', 'Thomer', '73733', 'Einkaufsstr. 55', 'Schopstadt', 'Gus@thomer.de', 065115635),
	('Petra', 'Müller', '66740', 'Hauptstr. 1', 'Saarlouis', 'Petra.Müller@web.de', 0683100000),
	('Hildegard', 'Bibelroy', '11111', 'Einsstr.11', 'Einsstadt', 'HildegardB@somepage.com', 11111111111),
	('Yildiz', 'Tilbe', '12487', 'Hauptstr. 200', 'Berlin', 'YildizTilbe@ghioapi.de', 017200011100),
	('Hermann', 'Buchmannklon', '01222', 'Straße 43', 'Stadt', 'buchmannklon@verwaltung.de', 028409275),
	('Alexandra', 'Dünsch', '73732', 'Einkaufsstr. 155', 'Klossstadt', 'Alexandra.dünsch@gmx.net', 049846433),
	('Fred', 'Fred', '41564', 'Whasstr. 12', 'Whasstart', 'Fred.Fred@fred.com', 01984354102),
	('Friedolin', 'Fred', '41564', 'Whasstr. 12', 'Whasstart', 'Friedolin.Fred@fred.com', 01984354000),
	('Freda', 'Fred', '41564', 'Whasstr.12', 'Whasstart', 'Freda.Fred@fred.com', 01984354111),
	('Peter', 'Ludolf', '56307', 'Mittelstr. 2', 'Dernbach', 'PeterLudolf@web.de', 026891259),
	('Uwe', 'Ludolf', '56307', 'Mittelstr. 2', 'Dernbach', 'PeterLudolf@web.de', 026891259),
	('Manfred', 'Ludolf', '56307', 'Mittelstr. 2', 'Dernbach', 'PeterLudolf@web.de', 026891259),
	('Peter', 'Schreiner', '54441', 'Kabuffstraße 8', 'Kanara', 'peter@gmx.de', 06581787878),
	('Günther', 'Knopfler', '54341', 'Kirschenweg 1', 'Betonia', 'günther69@gmx.de', 065173458568),
	('Luise', 'McKidney', '88076', 'Sackgässchen 1', 'Dorflo', 'luise@home.de', 0171443322);


INSERT INTO Werke (Name) VALUES
	('Hauptwerk'),
	('Werk Zwickau'),
	('Heinemann Werk'),
	('Gutes Werken am See'),
	('Outsourcing Elements'),
	('Güllen Werke GmbH');


INSERT INTO Mitarbeiter VALUES
	(1, '2011-11-11', 2000.00),
	(2, '2012-12-12',1800.00),
	(3, '1999-01-01', 1200.00),
	(5, '1999-02-02', 3400.40),
	(7, '2012-12-13',1600.00),
	(8, '2003-04-04', 800.21),
	(10, '2013-10-10', 1650.00),
	(11, '2013-10-10', 1650.00),
	(12, '2013-10-10', 1650.00),
	(13, '2010-10-10', 8000.00),
	(14, '2010-10-10', 8000.00),
	(15, '2010-10-10', 8000.00),
	(16, '2005-12-10', 2500.00),
	(17, '2005-12-20', 2300.00),
	(18, '2003-08-12', 2100.00);


INSERT INTO Werksarbeiter VALUES
	(1, 1),
	(5, 2),
	(17, 3);


INSERT INTO LKW_Fahrer VALUES 
	(10, '2009-01-01'),
	(11, '2008-02-02'),
	(12, '2007-03-03'),
	(18, '2007-05-03');


INSERT INTO Verwaltungsangestellte VALUES
	(3),(8);

INSERT INTO LAGERARBEITER VALUES
	(13),(14),(15),(16);

INSERT INTO Teilelagerarbeiter VALUES
	(13, 2),(14,2);


INSERT INTO Autolagerarbeiter VALUES
	(15), (16);


INSERT INTO Großhändler (Firmenname, Straße, PLZ, Ort, Rabatt) VALUES
	('Expensive Cars','Geschäftstr. 3', '12345', 'Counttown', 5),
	('Cheap Cars', 'Randstraße 9', '12345', 'Counttown', 25),
	('Lensen und Partner GmbH', 'Hauptstraße 1', '66551', 'Saarhausen', 0),
	('Autos 4 Life', 'Tortenstraße 4', '66151', 'Goldsilbern', 5),
	('Kadetten und Twingos GmbH', 'Rue de Kartoffel 17', '44251', 'Köpfern', 0);


INSERT INTO Modelle (Preis, Bezeichnung) VALUES
	(19999, 'Prototyp'),
	(11000, 'Billiger Prototyp'),
	(12000.99, 'Happy Hippo Car - Der Verkaufsschlager'),
	(13999, 'Twilight 500'),
	(9999.99, 'Karre');


INSERT INTO Kunden VALUES
	(1,100),(4, 300), (6, 104), (9, 304);


INSERT INTO Privatkunden VALUES
	(4),(9);


INSERT INTO Kontaktpersonen VALUES
	(1, 1),
	(6, 2);




--INSERT INTO Werksaufträge VALUES
-- (WID, AID, status)
	--(1, 0, 'WARTEND');


INSERT INTO Autoteiltypen (maxPreis, Bezeichnung) VALUES
	(100, 'Flügeltür Rot'),
	(100, 'Flügeltür Blau'),
	(200, 'Flügeltür Grün'),
	(100, 'Tür Blau'),
	(100, 'Tür Rot'),
	(100, 'Tür Grün'),
	(50, 'Fenster Tönung Blau'),
	(50, 'Fenster ohne Tönung'),
	(500, 'Karosserie Blau'),
	(600, 'Karosserie Grün'),
	(600, 'Karosserie Gelb'),
	(600, 'Karosserie Rot'),
	(100, 'Reifen klein'),
	(100, 'Reifen mittel'),
	(100, 'Reifen groß'),
	(2000, 'Motor schwach'),
	(3000, 'Motor gut'),
	(4000, 'Motor sportlich');


INSERT INTO Modellteile VALUES
--(Modell_ID, TeiletypID, Anzahl)
	(1, 1, 1), (1, 6, 1), (1, 8, 1), (1, 12, 1), (1, 17, 1),
	(2, 1, 1), (2, 6, 1), (2, 8, 1), (2, 13, 1), (2, 16, 1),
	(3, 1, 1), (3, 6, 1), (3, 8, 1), (3, 13, 1), (3, 15, 1),
	(4, 1, 1), (4, 6, 1), (4, 8, 1), (4, 13, 1), (4, 16, 1),
	(5, 1, 1), (5, 6, 1), (5, 8, 1), (5, 13, 1), (5, 16, 1);


--INSERT INTO Autos VALUES
--	;


INSERT INTO LKWs (Kaufdatum) VALUES
	('2010-01-10'),
	('2011-02-01'),
	('2010-02-01'),
	('2011-04-01'),
	('2014-02-01');


--INSERT INTO liefert VALUES
--	;

INSERT INTO Hersteller (Firmenname) VALUES
	('Teilezurichter - Profis und Azubis'),
	('Katalysatoren 4 Life'),
	('Teile gegen Bares'),
	('Items, Gadgets and more');


INSERT INTO produzieren VALUES
	(1, 1, 50.50),
	(1, 2, 50.50),
	(2, 1, 60.0),
	(3, 1, 60.0),
	(4, 1, 50.50),
	(5, 1, 50.50),
	(6, 2, 60.0),
	(7, 3, 60.0),
	(8, 3, 50.50),
	(9, 1, 50.50),
	(10, 2, 60.0),
	(11, 2, 60.0),
	(12, 1, 50.50),
	(13, 1, 50.50),
	(14, 1, 60.0),
	(15, 2, 60.0),
	(16, 3, 60.0),
	(17, 3, 60.0);


--INSERT INTO bestellt VALUES
--	;


INSERT INTO Autoteile (TeiletypID, lagert_in, Lieferdatum) VALUES
-- ( TeileID, TeiletypID, lagert_in, date, AID)
	(1, 1, '2013-01-12'),
	(2, 2, '2013-01-12'),
	(3, 1, '2013-01-12'),
	(4, 3, '2013-01-12'),
	(5, 1, '2013-01-12'),
	(6, 1, '2013-01-12'),
	(5, 1, '2013-01-12'),
	(7, 1, '2013-01-12'),
	(1, 3, '2013-01-12'),
	(2, 1, '2013-01-12'),
	(8, 1, '2013-01-12'),
	(1, 5, '2013-01-12'),
	(9, 5, '2013-01-12'),
	(1, 1, '2013-01-12'),
	(1, 6, '2013-01-12'),
	(2, 6, '2013-01-12'),
	(1, 1, '2013-01-12'),
	(12, 2, '2013-01-12');

	
INSERT INTO Motoren VALUES
	(15, 80, 7000, 5, 'Diesel'),
	(16, 120, 8000, 8, 'Diesel'),
	(17, 240, 10000, 12, 'Super');


INSERT INTO Karosserien VALUES
	(8, 'Blau', 'Blech', 80, 150, 200),
	(9, 'Grün', 'Carbon', 80, 150, 200),
	(10, 'Gelb', 'Blech', 80, 150, 200),
	(11, 'Rot', 'Zink', 80, 150, 200);


INSERT INTO Türen VALUES
	(1, 'Rot', 'FLÜGELTÜR'),
	(2, 'Blau', 'FLÜGELTÜR'),
	(3, 'Grün', 'FLÜGELTÜR'),
	(4, 'Blau', 'NORMAL'),
	(5, 'Rot', 'NORMAL'),
	(6, 'Grün', 'NORMAL');


INSERT INTO Fenster VALUES
	(7, 'Blau', 'Sicherheitsglas'),
	(8, 'klar', 'Saphirglas');


INSERT INTO Reifen VALUES
	(13, 'Blau', 17, 'Chrom'),
	(14, 'Grün', 18, 'Stahl'),
	(15, 'Schwarz', 20, 'Aluminium');


INSERT INTO Aufträge (Preis, Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES
-- (Preis, Modell_ID, Anzahl, Datum, KundenID, MitarbeiterID)
	(39998 , 1, 2, 1, 3);
