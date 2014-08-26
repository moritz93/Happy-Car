--Werksid not Null trigger 
--checked :)
CREATE FUNCTION checkWerksid() RETURNS TRIGGER AS
	$$ BEGIN
		IF(NEW.wid IS NULL) THEN RAISE EXCEPTION 'Wid bei Insert NULL';
		END IF; 
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;

	
CREATE TRIGGER validInsertWerksarbeiter BEFORE INSERT ON Werksarbeiter FOR EACH ROW EXECUTE PROCEDURE checkWerksid();

CREATE TRIGGER validInsertTeilelagerarbeiter BEFORE INSERT ON Teilelagerarbeiter FOR EACH ROW EXECUTE PROCEDURE checkWerksid();


--License at least three years trigger
--checked :)
--BEM: Genauigkeit auf Monat, Tage ignoriert.
CREATE FUNCTION checkLicenseDate() RETURNS TRIGGER AS
	$$ BEGIN
		IF(now() - NEW.führerscheindatum <= interval '3 years') THEN RAISE EXCEPTION 'Führerschein noch nicht lange genug';
		END IF;
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;
CREATE TRIGGER validInsertLKWFahrer BEFORE INSERT ON lkw_fahrer FOR EACH ROW EXECUTE PROCEDURE checkLicenseDate();

--began to work in past trigger
--checked :)
CREATE FUNCTION checkBeginn() RETURNS TRIGGER AS
	$$ BEGIN
		IF(NEW.beschäftigungsbeginn > now()) THEN RAISE EXCEPTION 'Beschäftigungsbeginn in der Zukunft';
		END IF; 
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;
CREATE TRIGGER validInsertMitarbeiter BEFORE INSERT ON mitarbeiter FOR EACH ROW EXECUTE PROCEDURE checkBeginn();



--New Delivery trigger
--checked :)
CREATE FUNCTION newDelivery() RETURNS TRIGGER AS
	$$ BEGIN
		UPDATE Autos SET Status='LIEFERND' WHERE kfz_id=NEW.kfz_id AND modell_id=NEW.modell_id;
		RETURN NEW;
	END;$$ LANGUAGE plpgsql;


CREATE TRIGGER setOnDelivery AFTER INSERT ON liefert FOR EACH ROW EXECUTE PROCEDURE newDelivery();

--Delivery finished trigger
--checked :)
CREATE FUNCTION finishedDelivery() RETURNS TRIGGER AS
	$$ BEGIN
		UPDATE Autos SET Status='ARCHIVIERT' WHERE kfz_id=OLD.kfz_id AND modell_id=OLD.modell_id;
		RETURN OLD;
	END; $$ LANGUAGE plpgsql;
CREATE TRIGGER setOnDeliveryFinished AFTER DELETE ON liefert FOR EACH ROW EXECUTE PROCEDURE finishedDelivery();

--car parts arrived
CREATE FUNCTION carPartsArrived() RETURNS TRIGGER AS
	$$ 
	DECLARE
		teilid integer;
	BEGIN
		IF (OLD.Status='ARCHIVIERT' OR NEW.Status!='ARCHIVIERT') THEN RETURN NEW; END IF;
		SELECT max(TeileID) INTO teilid FROM Autoteile;
		INSERT INTO Autoteile (TeileId ,TeiletypID, lagert_in, Lieferdatum, AID) VALUES (teilid+1,OLD.TeiletypID, OLD.WID, now(), OLD.AID);
		RETURN OLD;
	END; $$ LANGUAGE plpgsql;
-- TODO Falls wir eine archivtabelle einführen, dann bei OnDelete, ansonsten bei Update
CREATE TRIGGER setOnCarPartsArrived AFTER UPDATE ON bestellt FOR EACH ROW EXECUTE PROCEDURE carPartsArrived();


--on insert Werksaufträge
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
		

CREATE FUNCTION insertInJobs() RETURNS TRIGGER AS
	$$ 
	DECLARE
		missing boolean;
		neededParts integer;
		part integer;

		
		-- debug print
		countNeeded integer;
		
	BEGIN		
		countNeeded := (SELECT Anzahl FROM Aufträge WHERE AID=NEW.AID);
		missing:=EXISTS (SELECT * FROM 
			-- Wähle Autoteile, die keinem Auftrag zugeordnet sind (AID ist NULL)
			((SELECT TeiletypID, count(*) FROM Autoteile WHERE lagert_in = NEW.WID AND AID IS NULL GROUP BY TeiletypID) AS tmp1
			 NATURAL JOIN
			--Anzahl benötigter Teile um NEW.Anzahl Autos herzustellen
			(SELECT TeiletypID, Anzahl * countNeeded FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID = NEW.AID)) AS tmp2)
		WHERE countNeeded>count) AS missingParts;
		
		--Sind genügend Teile im Lager?
		IF (missing) THEN --NEIN
			-- RAISE NOTICE 'Parts missing: %', missing;
			--Iteriere über benötigte Teile
			FOR part IN (SELECT TeiletypID FROM Modellteile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID))
			LOOP
				--RAISE NOTICE 'TeiletypId: %', part;
				--Anzahl wieoft Teil gebraucht wird.
				neededParts := (SELECT Anzahl*(SELECT Anzahl FROM Aufträge WHERE AID=NEW.AID) FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID) AND TeiletypID = part);

				IF(neededParts > 0) THEN
					--RAISE NOTICE 'neededParts_missing: %', neededParts;
					--Bestelle die Teile
					INSERT INTO bestellt (HID, WID, TeiletypID, Anzahl, Bestelldatum, AID) VALUES 
							      (getBestManufacturer(part), NEW.WID, part, neededParts, now(), NEW.AID);
				END IF;
			END LOOP;
		ELSE --JA
			--RAISE NOTICE 'Parts missing: %', missing;
			--Iteriere über benötigte Teile
			FOR part IN (SELECT TeiletypID FROM Modellteile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID))
			LOOP
				--Anzahl wieoft Teil gebraucht wird.
				neededParts:=(SELECT Anzahl*(SELECT Anzahl FROM Aufträge WHERE AID=NEW.AID) FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID) AND TeiletypID=part);
				IF(neededParts > 0) THEN
				--RAISE NOTICE 'neededParts_in_stock: %', neededParts;
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
			END IF;
		END IF;	
		RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;

CREATE TRIGGER onInsertWerksaufträge AFTER INSERT ON Werksaufträge FOR EACH ROW EXECUTE PROCEDURE insertInJobs();




-- TODO get estimated time for car prduction
CREATE OR REPLACE FUNCTION getWerksauslastung(integer) RETURNS integer AS
	$$
	DECLARE
	aid integer;
	expectedTime integer;
	liefer date;
		
	BEGIN
	FOR aid IN (SELECT AID FROM Werksaufträge WHERE WID=$1)
	LOOP
		liefer=SELECT Vorraussichtliches_Lieferdatum FROM Aufträge;
		
		
	END;
	$$ LANGUAGE plpgsql;


-- TODO check if ordered cars are already produced
-- Param (Modell_ID, Anzahl)
CREATE OR REPLACE FUNCTION checkCarStock(integer, integer) RETURNS boolean AS
	$$
	DECLARE 
	counting integer;
	BEGIN
	counting=(SELECT count(*) AS Anzahl FROM Autos WHERE Modell_ID = $1 AND Status='LAGERND');
	RETURN counting>=$2;
	END;
	$$ LANGUAGE plpgsql;


-- TODO check if a LKW is available - returns LKW_ID or null
-- Param ()
CREATE OR REPLACE FUNCTION checkLkwAvailable() RETURNS integer AS
	$$
	BEGIN
		RETURN
		(	(SELECT LKW_ID FROM LKWs
			EXCEPT
			SELECT LKW_ID FROM liefert)
			ORDER BY LKW_ID ASC
			FETCH FIRST 1 ROWS ONLY
		);
	END;
	$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION checkDriverAvailable() RETURNS integer AS
	$$
	BEGIN
	RETURN (	(SELECT PID FROM LKW_Fahrer 
			EXCEPT 
			SELECT MID AS PID FROM liefert) 
			ORDER BY PID ASC 
			FETCH FIRST 1 ROWS ONLY
	);
	END;
	$$ LANGUAGE plpgsql;

-- onInsert Aufträge, teile Auftrag bestimmtem Werk zu oder liefere ggf. direkt zum kunden
-- TODO
CREATE OR REPLACE FUNCTION insertInOrders() RETURNS TRIGGER AS
	$$
	DECLARE
	orderInStock boolean;
	
	BEGIN
	orderInStock := checkCarStock(NEW.Modell_ID, NEW.Anzahl);

	-- Autos sind schon im Autolager
	IF orderInStock THEN
		-- TODO
		-- lkws available?
		-- vorraussichtliche Lieferzeit mittels KundenDistanz berechnen


		
	-- Autos sind noch nicht produziert
	ELSE
	--TODO
	
	END IF;
	RETURN NULL;
	END;
	$$ LANGUAGE plpgsql;
	
CREATE TRIGGER onInsertAufträge AFTER INSERT ON Aufträge FOR EACH ROW EXECUTE PROCEDURE insertInOrders();

--Bei Einchecken eines fertigen Auftrags, Einfügen der Autos
CREATE FUNCTION finishedJob() RETURNS TRIGGER AS
	$$
	DECLARE
	counter integer;
	modellid integer;
	werk integer;	
	kfzid integer;
	BEGIN
	--Es wird nur etwas getan, falls die Änderung auch von bel Status zu AUSGEFÜHRT war
	IF (OLD.Status='AUSGEFÜHRT' OR NEW.Status!='AUSGEFÜHRT') THEN 
		RETURN NULL;
	END IF;
	modellid=(SELECT Modell_ID FROM Aufträge WHERE AID=OLD.AID);
	werk=(SELECT WID FROM Werksauftäge WHERE AID=WID);
	counter=(SELECT Anzahl FROM Aufträge WHERE AID=OLD.AID);
	--Gibt es einen freien LKW und Fahrer?
	IF (checkLkwAvailable() IS NULL OR checkDriverAvailable() IS NULL) THEN --NEIN, dann Lagere Autos vorübergehend
		LOOP
			EXIT WHEN counter=0;
			INSERT INTO Autos (Modell_ID, Status, produziertVon) VALUES (modellid, 'LAGERND', werk);
			counter=counter-1;
		END LOOP;
	ELSE --JA, dann liefere sofort.
		LOOP
			EXIT WHEN counter=0;
			INSERT INTO Autos (Modell_ID, Status, produziertVon) VALUES (modellid, 'LIEFERND', werk);
			kfzid=(SELECT max(KFZ_ID) FROM Autos);
			INSERT INTO liefert (LKW_ID, KFZ_ID, Modell_ID, MID, AID, Lieferdatum) VALUES (checkLkwAvailable(), kfzid+1, modellid, checkDriverAvailable(), OLD.AID, now());
			counter=counter-1;
		END LOOP;
	DELETE FROM Autoteile WHERE AID=OLD.AID;
	END IF;
	END;
	$$ LANGUAGE plpgsql;

CREATE TRIGGER onFinishedJob AFTER UPDATE ON Werksaufträge FOR EACH ROW EXECUTE PROCEDURE finishedJob();
