--Lieferungen können nicht gelöscht werden, stattdessen werden sie archiviert.
--@param $1 - Die KFZ_ID des Fahrzeugs, das geliefert wurde
--@param $2 - Die Modell_ID des Fahrzeugs
--@param $3 - Die ID des LKW-Fahrers
--@param $4 - Die ID des Auftrags.
CREATE FUNCTION finishedDelivery(integer, integer, integer, integer) RETURNS boolean AS
	$$ BEGIN
		UPDATE Autos SET Status='ARCHIVIERT' WHERE kfz_id=$1 AND modell_id=$2;
		UPDATE liefert SET Lieferdatum=CURRENT_DATE WHERE KFZ_ID=$1 AND MID=$3 AND AID=$4;
		UPDATE Aufträge SET Status='ARCHIVIERT' WHERE AID=$4;
		RETURN true;
	END; $$ LANGUAGE plpgsql;
CREATE RULE setOnDeliveryFinished AS ON DELETE TO liefert DO INSTEAD SELECT finishedDelivery(OLD.kfz_id, OLD.modell_id, OLD.MID, OLD.AID);

--Startet in einem Werk den nächsten Auftrag, falls möglich.
--@param $1 - Das Werk, in dem geprüft werden soll
CREATE FUNCTION checkAvailableWork(integer) RETURNS boolean AS
	$$
	DECLARE 
	auftrag integer;
	countNeeded integer;
	available boolean;
	notmissing boolean;
	BEGIN
	IF(EXISTS (SELECT 1 FROM Werksaufträge WHERE WID=$1 AND Status='IN_BEARBEITUNG') )
		THEN RETURN false; 
	END IF;
	FOR auftrag IN SELECT AID FROM Werksaufträge WHERE WID=$1
	LOOP
		countNeeded := (SELECT Anzahl FROM Aufträge WHERE AID=auftrag);
		available:=(NOT EXISTS (SELECT 1 FROM 
			-- Wähle Autoteile, die diesem Auftrag zugeordnet sind
			((SELECT TeiletypID, count(*) FROM Autoteile WHERE lagert_in = $1 AND AID=auftrag GROUP BY TeiletypID) AS tmp1
			 RIGHT OUTER JOIN
			--Anzahl benötigter Teile um NEW.Anzahl Autos herzustellen
			(SELECT TeiletypID, (Anzahl * countNeeded) AS teileNeeded FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM 				Aufträge WHERE AID = auftrag)) AS tmp2
			ON tmp1.TeiletypID=tmp2.TeiletypID)
			WHERE teileNeeded>count OR count IS NULL LIMIT 1));
		--Sind genügend Teile im Lager?
		IF (available) THEN
			IF(NOT EXISTS (SELECT * FROM Werksaufträge WHERE Status='IN_BEARBEITUNG' AND WID=$1)) THEN
				UPDATE Werksaufträge SET Status='IN_BEARBEITUNG' WHERE WID=$1 AND AID=auftrag;
				UPDATE Werksaufträge SET Herstellungsbeginn=CURRENT_DATE WHERE WID=$1 AND AID=auftrag;
				RETURN true;
			END IF;
		END IF;
		notmissing:=(NOT EXISTS (SELECT 1 FROM 
			-- Wähle Autoteile, die keinem Auftrag zugeordnet sind (AID ist NULL)
			((SELECT TeiletypID, count(*) FROM Autoteile WHERE lagert_in = $1 AND AID IS NULL GROUP BY TeiletypID) AS tmp1
			 RIGHT OUTER JOIN
			--Anzahl benötigter Teile um NEW.Anzahl Autos herzustellen
			(SELECT TeiletypID, (Anzahl * countNeeded) AS teileNeeded FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM 				Aufträge WHERE AID =auftrag)) AS tmp2
			ON tmp1.TeiletypID=tmp2.TeiletypID)
			WHERE teileNeeded>count OR count IS NULL LIMIT 1));
		IF (notmissing) THEN
			IF(NOT EXISTS (SELECT * FROM Werksaufträge WHERE Status='IN_BEARBEITUNG' AND WID=$1)) THEN
				UPDATE Werksaufträge SET Status='IN_BEARBEITUNG' WHERE WID=$1 AND AID=auftrag;
				UPDATE Werksaufträge SET Herstellungsbeginn=CURRENT_DATE WHERE WID=$1 AND AID=auftrag;
				RETURN true;
			END IF;
		END IF;
	END LOOP;
	RETURN false;
END; $$ LANGUAGE plpgsql;

--Sobald Teile ankommen muss geprüft werden, ob ein Auftrag zum Ausführen bereit ist.
CREATE FUNCTION carPartsArrived() RETURNS TRIGGER AS
	$$ 
	DECLARE
		teilid integer;
		countNeeded integer;
		available boolean;
		counter integer;
	BEGIN
		counter:=OLD.Anzahl;
		IF (OLD.Status='ARCHIVIERT' OR NEW.Status!='ARCHIVIERT') THEN RETURN NEW; END IF;
		LOOP
		EXIT WHEN counter=0;
			INSERT INTO Autoteile (TeiletypID, lagert_in, Lieferdatum, AID) VALUES (OLD.TeiletypID, OLD.WID, now(), OLD.AID);
			UPDATE Autoteile SET Lieferdatum=CURRENT_DATE WHERE TeileID=lastVal();
			counter=counter-1;		
		END LOOP;	
		PERFORM checkAvailableWork(OLD.WID);
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;

CREATE TRIGGER setOnCarPartsArrived AFTER UPDATE ON bestellt FOR EACH ROW EXECUTE PROCEDURE carPartsArrived();



--Wählt aus bei welchem Hersteller ein Teil bestellt werden soll.
--@param $1 - Die ID des Teiletyps, der bestellt werden soll.
CREATE FUNCTION getBestManufacturer(integer) RETURNS integer AS 
	$$ BEGIN
		RETURN
		(SELECT HID FROM
			(SELECT * FROM produzieren WHERE TeiletypID=$1
			ORDER BY Zeit ASC
			FETCH FIRST 3 ROWS ONLY
			) AS tmp
		ORDER BY Preis ASC
		FETCH FIRST 1 ROWS ONLY
		);			
	END; $$ LANGUAGE plpgsql;


-- Wenn ein neuer Auftrag im Werk ankommt muss das Lager geprüft werden, eventuell Teile bestellt werden und eine Produktion kann unter Umständen schon beginnen.
CREATE FUNCTION insertInJobs() RETURNS TRIGGER AS
	$$ 
	DECLARE
		missing boolean;
		neededParts integer;
		part integer;
		
		countNeeded integer;
		
	BEGIN		
		countNeeded := (SELECT Anzahl FROM Aufträge WHERE AID=NEW.AID);
		missing:=(EXISTS (SELECT 1 FROM 
			-- Wähle Autoteile, die keinem Auftrag zugeordnet sind (AID ist NULL)
			((SELECT TeiletypID, count(*) FROM Autoteile WHERE lagert_in = NEW.WID AND AID IS NULL GROUP BY TeiletypID) AS tmp1
			 RIGHT OUTER JOIN
			--Anzahl benötigter Teile um NEW.Anzahl Autos herzustellen
			(SELECT TeiletypID, (Anzahl * countNeeded) AS teileNeeded FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM 				Aufträge WHERE AID = NEW.AID)) AS tmp2
			ON tmp1.TeiletypID=tmp2.TeiletypID)
			WHERE teileNeeded>count OR count IS NULL LIMIT 1));
		--Sind genügend Teile im Lager?
		IF (missing) THEN --NEIN
			--Iteriere über benötigte Teile
			FOR part IN (SELECT TeiletypID FROM Modellteile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID))
			LOOP
				--Anzahl wieoft Teil gebraucht wird.
				neededParts := (SELECT Anzahl*(SELECT Anzahl FROM Aufträge WHERE AID=NEW.AID) FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID) AND TeiletypID = part);

				IF(neededParts > 0) THEN
					--Bestelle die Teile
					INSERT INTO bestellt (HID, WID, TeiletypID, Anzahl, Bestelldatum, AID) VALUES 
							      (getBestManufacturer(part), NEW.WID, part, neededParts, now(), NEW.AID);
				END IF;
			END LOOP;
		ELSE --JA
			--Iteriere über benötigte Teile
			FOR part IN (SELECT TeiletypID FROM Modellteile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID))
			LOOP
				--Anzahl wieoft Teil gebraucht wird.
				neededParts:=(SELECT Anzahl*(SELECT Anzahl FROM Aufträge WHERE AID=NEW.AID) FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID) AND TeiletypID=part);
				IF(neededParts > 0) THEN
					--Bestelle die Teile
					INSERT INTO bestellt (HID, WID, TeiletypID, Anzahl, Bestelldatum, AID) VALUES 
							      (getBestManufacturer(part), NEW.WID, part, neededParts, now(), NULL);
					--Setze bei genau einem Teil des benötigten Typs den Auftragsstatus
					UPDATE Autoteile SET AID=NEW.AID FROM (SELECT TeileID FROM Autoteile WHERE TeiletypID=part AND AID IS NULL ORDER BY ID ASC LIMIT neededParts) AS alias;
				END IF;
			END LOOP;
			-- Es sind alle Teile da, wird irgendein auftrag gerade aufgeführt? Wenn nein dann führe diesen hier aus.
			IF(NOT EXISTS (SELECT * FROM Werksaufträge WHERE Status='IN_BEARBEITUNG' AND WID=NEW.WID)) THEN
				UPDATE Werksaufträge SET Status='IN_BEARBEITUNG' WHERE WID=NEW.WID AND AID=NEW.AID;
				UPDATE Werksaufträge SET Herstellungsbeginn=CURRENT_DATE WHERE WID=NEW.WID AND AID=NEW.AID;
			END IF;
		END IF;	
		RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;

CREATE TRIGGER onInsertWerksaufträge AFTER INSERT ON Werksaufträge FOR EACH ROW EXECUTE PROCEDURE insertInJobs();




--Schätzt die Werksauslastung ab, wird benötigt um Lieferzeiten zu prognostizieren und Aufträge auf Werke zu verteilen.
--@param $1 - Die Id des Werkes, das abgeschätzt werden soll.
CREATE OR REPLACE FUNCTION getWerksauslastung(integer) RETURNS interval AS
	$$
	DECLARE
	auftrag integer;
	expectedTime numeric(20,2);
	liefer date;
	switchCounter integer;
	BEGIN
	switchCounter:=0;
	expectedTime=0;
	FOR auftrag IN (SELECT Werksaufträge.AID FROM Werksaufträge WHERE WID=$1 AND Status='WARTEND')
	LOOP
		switchCounter:=switchCounter +1;
		liefer:=(SELECT Vorraussichtliches_Lieferdatum FROM Aufträge WHERE AID=auftrag);
		expectedTime = expectedTime + (liefer - CURRENT_DATE)+0.8;
	END LOOP;
	expectedTime=expectedTime + switchCounter;
	IF(EXISTS(SELECT 1 FROM Werksaufträge WHERE WID=$1 AND Status='IN_BEARBEITUNG')) THEN
		expectedTime=expectedTime + 0.35;
	END IF;
	RETURN CEIL(expectedTime) * interval '1 days';
	END;
	$$ LANGUAGE plpgsql;


--Schätzt die Fahrzeit nach Distanz ab.
--@param $1 - Die Distanz in KM, die zu fahren ist.
CREATE OR REPLACE FUNCTION getTimeForDistance(integer) RETURNS interval AS
	$$
	BEGIN
	-- 50km/h
	RETURN CEIL(($1/50)/24)*interval '1 days';
	END;
	$$ LANGUAGE plpgsql;


-- Überprüft, ob bestellte Autos bereits im Lager verfügbar sind.
--@param $1 - Die Modell_ID, der gewünschten Fahrzeuge
--@param $2 - Die Anzahl der gewünschten Fahrzeuge
CREATE OR REPLACE FUNCTION checkCarStock(integer, integer) RETURNS boolean AS
	$$
	DECLARE 
	counting integer;
	BEGIN
	counting = (SELECT count(*) AS Anzahl FROM Autos WHERE Modell_ID = $1 AND Status = 'LAGERND');
	RETURN counting >= $2;
	END;
	$$ LANGUAGE plpgsql;


--Prüft, ob ein LKW zur Lieferung verfügbar ist.
CREATE OR REPLACE FUNCTION checkLkwAvailable() RETURNS integer AS
	$$
	BEGIN
		RETURN
		(	(SELECT LKW_ID FROM LKWs
			EXCEPT
			SELECT LKW_ID FROM liefert WHERE Lieferdatum IS NULL)
			ORDER BY LKW_ID ASC
			FETCH FIRST 1 ROWS ONLY
		);
	END;
	$$ LANGUAGE plpgsql;


-- Prüft, ob ein Fahrer zur Lieferung verfügbar ist.
CREATE OR REPLACE FUNCTION checkDriverAvailable() RETURNS integer AS
	$$
	BEGIN
	RETURN (	(SELECT PID FROM LKW_Fahrer 
			EXCEPT 
			SELECT MID AS PID FROM liefert WHERE Lieferdatum IS NULL) 
			ORDER BY PID ASC 
			FETCH FIRST 1 ROWS ONLY
	);
	END;
	$$ LANGUAGE plpgsql;



--Sobald ein neuer Auftrag ankommt, muss geprüft werden, ob die Autos schon im Lager verfügbar sind, ansonsten wird der Produktionsauftrag einem Werk mit geringer Auslastung zugewiesen.
CREATE OR REPLACE FUNCTION insertInOrders() RETURNS TRIGGER AS
	$$
	DECLARE
	orderInStock boolean;
	counter integer;
	cars integer;
	driver integer;
	lkw integer;
	distance integer;
	werk integer;
	minwerktime interval;
	minwerkid integer;
	
	BEGIN
	minwerkid:=(SELECT WID FROM Werksaufträge LIMIT 1);
	IF(minwerkid IS NULL) THEN minwerkid:=(SELECT WID FROM Werke LIMIT 1); END IF;
	minwerktime:=getWerksauslastung(minwerkid); 
	orderInStock := checkCarStock(NEW.Modell_ID, NEW.Anzahl);
	driver := checkDriverAvailable();
	lkw := checkLkwAvailable();
	distance := (SELECT Distanz FROM Kunden WHERE PID = (SELECT KundenID FROM Aufträge WHERE AID=NEW.AID));
	counter := (SELECT Anzahl FROM Aufträge WHERE AID=NEW.AID);
	
	-- Autos sind schon im Autolager
	IF orderInStock THEN
		UPDATE Aufträge SET Vorraussichtliches_Lieferdatum=now()+getTimeForDistance(distance) WHERE AID=NEW.AID;
		IF (lkw IS NULL OR driver IS NULL) THEN
			--NEIN, dann Lagere Autos vorübergehend
			UPDATE Autos SET Status='WARTEND' WHERE Modell_ID = NEW.Modell_ID AND KFZ_ID IN (SELECT KFZ_ID FROM Autos WHERE Modell_ID=NEW.Modell_ID);
		ELSE --JA, dann liefere sofort.
			FOR cars IN (SELECT KFZ_ID FROM Autos WHERE Modell_ID = NEW.Modell_ID AND Status = 'LAGERND')
			LOOP
			EXIT WHEN counter = 0;
				INSERT INTO liefert (LKW_ID, KFZ_ID, Modell_ID, MID, AID, Lieferdatum) VALUES (lkw, cars, NEW.Modell_ID, driver, NEW.AID, NULL);
				counter=counter-1;
			END LOOP;
		END IF;
	ELSE	--NEIN, dann produziere
		FOR werk IN (SELECT WID FROM Werke)
		LOOP
			IF (minwerktime>=getWerksauslastung(werk)) THEN
				minwerktime=getWerksauslastung(werk);
				minwerkid=werk;
			END IF;
		END LOOP;
		--FOR werk IN (SELECT WID FROM Werke)
		--LOOP
		--	IF((SELECT WID FROM Werksaufträge WHERE WID=werk AND Status='IN_BEARBEITUNG') IS NULL) THEN
		--		minwerkid:=werk;
		--	END IF;
		--END LOOP;
		UPDATE Aufträge SET Vorraussichtliches_Lieferdatum=now()+minwerktime+getTimeForDistance(distance)+(CEIL(counter*1.5/24)*interval '1 days') WHERE AID=NEW.AID;
		INSERT INTO Werksaufträge (WID, AID) VALUES (minwerkid, NEW.AID);			
	
	END IF;
	RETURN NULL;
	END;
	$$ LANGUAGE plpgsql;
	
CREATE TRIGGER onInsertAufträge AFTER INSERT ON Aufträge FOR EACH ROW EXECUTE PROCEDURE insertInOrders();



--Bei Einchecken eines fertigen Auftrags werden die Autos eingefügt.
CREATE FUNCTION finishedJob() RETURNS TRIGGER AS
	$$
	DECLARE
	counter integer;
	modellid integer;
	werk integer;	
	kfzid integer;
	lkw integer;
	fahrer integer;
	BEGIN
	lkw=checkLkwAvailable();
	fahrer=checkDriverAvailable();
	--Setze Startpunkt in Aufträge
	IF(OLD.Status!='IN_BEARBEITUNG' AND NEW.status='IN_BEARBEITUNG')THEN
		UPDATE Aufträge SET Status = 'IN_BEARBEITUNG' WHERE NEW.Aid = Aufträge.AID;
	END IF;
	--Es wird nur etwas getan, falls die Änderung auch von bel Status zu AUSGEFÜHRT war
	IF (OLD.Status='ARCHIVIERT' OR NEW.Status!='ARCHIVIERT') THEN 
		RETURN NULL;
	END IF;
	modellid=(SELECT Modell_ID FROM Aufträge WHERE AID=OLD.AID);
	werk=(SELECT WID FROM Werksaufträge WHERE AID=OLD.AID);
	counter=(SELECT Anzahl FROM Aufträge WHERE AID=OLD.AID);
	UPDATE Werksaufträge SET Herstellungsende=CURRENT_DATE WHERE WID=OLD.WID AND AID=OLD.AID;
	--Gibt es einen freien LKW und Fahrer?
	IF (lkw IS NULL OR fahrer IS NULL) THEN --NEIN, dann Lagere Autos vorübergehend
		LOOP
			EXIT WHEN counter=0;
			INSERT INTO Autos (Modell_ID, Status, produziertVon) VALUES (modellid, 'WARTEND', werk);
			counter=counter-1;
		END LOOP;
	ELSE --JA, dann liefere sofort.
		LOOP
			EXIT WHEN counter=0;
			INSERT INTO Autos (Modell_ID, Status, produziertVon) VALUES (modellid, 'LAGERND', werk);
			kfzid=(SELECT max(KFZ_ID) FROM Autos);
			INSERT INTO liefert (LKW_ID, KFZ_ID, Modell_ID, MID, AID, Lieferdatum) VALUES (lkw, kfzid, modellid, fahrer, OLD.AID, NULL);
			counter=counter-1;
		END LOOP;
	DELETE FROM Autoteile WHERE AID=OLD.AID;
	END IF;
	RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;

CREATE TRIGGER onFinishedJob AFTER UPDATE ON Werksaufträge FOR EACH ROW EXECUTE PROCEDURE finishedJob();

--Berechnet den Preis zu einer Bestellung eines Kunden.
CREATE FUNCTION calculatePrice() RETURNS TRIGGER AS
	$$
	DECLARE
	var_rabatt integer;
	price numeric(10,2);
	
	BEGIN
	var_rabatt := 0;
	-- Kunde ist Kontaktperson / Großhändler
	IF (EXISTS (SELECT 1 FROM Kontaktpersonen WHERE PID = NEW.KundenID)) THEN
		var_rabatt := (SELECT Rabatt FROM ( SELECT *
						FROM Aufträge
						JOIN Kontaktpersonen
						ON NEW.KundenID = Kontaktpersonen.PID
					     ) AS tmp1
					JOIN Großhändler
					ON tmp1.GID = Großhändler.GID LIMIT 1);	
	END IF;
	price := (100-var_rabatt) * (SELECT Preis FROM Modelle WHERE NEW.Modell_ID = Modelle.Modell_ID) * NEW.Anzahl/100;
	UPDATE Aufträge SET Preis = price WHERE Aufträge.AID = NEW.AID;
	RETURN NEW;
	END; $$ LANGUAGE plpgsql;
	
CREATE TRIGGER calculatePrice AFTER INSERT ON Aufträge FOR EACH ROW EXECUTE PROCEDURE calculatePrice();
		

