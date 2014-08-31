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
	('Alexandra', 'Dünsch', '73732', 'Einkaufsstr. 155', 'Klossstadt', 'Alexandra.dünsch@gmx.net', 049846433);

INSERT INTO Werke (Name) VALUES
	('Gutes Werken am See');

INSERT INTO Mitarbeiter VALUES
	(1, '2011-11-11', 2000.00),
	(2, '2012-12-12',1800.00),
	(3, '1999-01-01', 1200.00),
	(4, '1999-02-02', 3400.40),
	(5, '2012-12-13',1600.00),
	(6, '2003-04-04', 800.21);

INSERT INTO Werksarbeiter VALUES
	(1, 1);

INSERT INTO LKW_Fahrer VALUES 
	(2, '2009-01-01');

INSERT INTO Verwaltungsangestellte VALUES
	(3);

INSERT INTO Lagerarbeiter VALUES
	(4),(6);

INSERT INTO Teilelagerarbeiter VALUES
	(4, 1);

INSERT INTO Autolagerarbeiter VALUES
	(6);

INSERT INTO Großhändler (Firmenname, Straße, PLZ, Ort, Rabatt) VALUES
	('Lensen und Partner GmbH', 'Hauptstraße 1', '66551', 'Saarhausen', 0),
	('Kadetten und Twingos GmbH', 'Rue de Kartoffel 17', '44251', 'Köpfern', 0);

INSERT INTO Modelle (Preis, Bezeichnung) VALUES
	(12000.99, 'Happy Hippo Car - Der Verkaufsschlager'),
	(13999, 'Twilight 500'),
	(9999.99, 'Karre');

INSERT INTO Kunden VALUES
	(7,100),(8, 300), (9, 104), (10, 304);

INSERT INTO Privatkunden VALUES
	(7),(8);

INSERT INTO Kontaktpersonen VALUES
	(9, 1),
	(10, 2);

INSERT INTO Autoteiltypen (maxPreis, Bezeichnung) VALUES
	(100, 'Flügeltür Rot'),
	(100, 'Tür Blau'),
	(50, 'Fenster Tönung Blau'),
	(500, 'Karosserie Blau'),
	(100, 'Reifen klein'),
	(2000, 'Motor schwach');

INSERT INTO Modellteile VALUES
--(Modell_ID, TeiletypID, Anzahl)
	(1, 1, 1), (1, 2, 1), (1, 6, 1),
	(2, 3, 1), (2, 4, 1), (2, 6, 1),
	(3, 5, 1), (3, 6, 1), (3, 1, 1);

INSERT INTO LKWs (Kaufdatum) VALUES
	('2010-01-10'),
	('2011-02-01');

INSERT INTO Hersteller (Firmenname) VALUES
	('Teilezurichter - Profis und Azubis'),
	('Katalysatoren 4 Life'),
	('Teile gegen Bares'),
	('Items, Gadgets and more');


INSERT INTO produzieren VALUES
	(1, 1, 50.50, 2),
	(2, 2, 50.50, 3),
	(3, 3, 60.0, 4),
	(4, 4, 60.0, 1),
	(5, 1, 50.50, 2),
	(6, 2, 50.50, 1),
	(1, 3, 60.0, 4),
	(2, 4, 60.0, 2),
	(3, 1, 50.50, 4),
	(4, 2, 50.50, 3);

INSERT INTO Autoteile (TeiletypID, lagert_in, Lieferdatum) VALUES
-- (TeiletypID, lagert_in, lieferdate)
	(1, 1, '2013-01-12'),
	(2, 1, '2013-01-12'),
	(3, 1, '2013-01-12'),
	(4, 1, '2013-01-12'),
	(5, 1, '2013-01-12'),
	(6, 1, '2013-01-12'),
	(1, 1, '2013-01-12'),
	(2, 1, '2013-01-12'),
	(3, 1, '2013-01-12'),
	(4, 1, '2013-01-12');
	
INSERT INTO Motoren VALUES
	(6, 80, 7000, 5, 'Diesel');

INSERT INTO Karosserien VALUES
	(4, 'Blau', 'Blech', 80, 150, 200);

INSERT INTO Türen VALUES
	(1, 'Rot', 'FLÜGELTÜR');

INSERT INTO Fenster VALUES
	(3, 'Blau', 'Sicherheitsglas');

INSERT INTO Reifen VALUES
	(5, 'Blau', 17, 'Chrom');


INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, mitarbeiterID) VALUES
-- ( Modell_ID, Anzahl, KundenID, MitarbeiterID)
	(1, 2, 7, 3);
