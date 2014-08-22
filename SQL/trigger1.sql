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
-- TODO trigger on delete nur bei Archivtabelle, falls nur status dann on update
CREATE FUNCTION carPartsArrived() RETURNS TRIGGER AS
	$$ 
	DECLARE
		teilid integer;
	BEGIN
		SELECT max(TeileID) INTO teilid FROM Autoteile;
		INSERT INTO Autoteile (TeileId ,TeiletypID, lagert_in, Lieferdatum, AID) VALUES (teilid+1,OLD.TeiletypID, OLD.WID, now(), OLD.AID);
		RETURN OLD;
	END; $$ LANGUAGE plpgsql;
CREATE TRIGGER setOnCarPartsArrived BEFORE DELETE ON bestellt FOR EACH ROW EXECUTE PROCEDURE carPartsArrived();


--on insert Werksaufträge
CREATE FUNCTION getBestManufacturer(integer) RETURNS integer AS 
	$$ BEGIN
		RETURN (SELECT HID FROM
			(SELECT * FROM produzieren WHERE TeiletypID=$1
			ORDER BY Zeit ASC
			FETCH FIRST 3 ROWS ONLY) AS tmp
			WHERE Preis=(SELECT min(Preis) FROM tmp));
	END; $$ LANGUAGE plpgsql;
		

CREATE FUNCTION insertInJobs() RETURNS TRIGGER AS
	$$ 
	DECLARE
		missing boolean;
		neededParts integer;
		part RECORD;
	BEGIN

		missing:=EXISTS (SELECT * FROM 
			--Wähle Autoteile, die keinem Auftrag zugeordnet sind (AID ist NULL)
			((SELECT TeiletypID, count(*) FROM Autoteile WHERE AID IS NULL GROUP BY TeiletypID) AS tmp1
			 NATURAL JOIN
			--Anzahl benötigter Teile um NEW.Anzahl Autos herzustellen
			(SELECT TeiletypID, Anzahl*(SELECT Anzahl FROM Aufträge WHERE AID=NEW.AID) AS countNeeded FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID)) AS tmp2)
		WHERE countNeeded>count) AS missingParts;
		--Sind genügend Teile im Lager?
		IF (missing) THEN --NEIN
			--Iteriere über benötigte Teile
			FOR part IN (SELECT TeiletypID FROM Modellteile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID))
			LOOP
				--Anzahl wieoft Teil gebraucht wird.
				neededParts:=(SELECT Anzahl*(SELECT Anzahl FROM Aufträge WHERE AID=NEW.AID) FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID) AND TeiletypID=part);
				LOOP
					IF(neededParts=0) THEN EXIT; END IF;
					--Bestelle die Teile
					INSERT INTO bestellt (HID, WID, TeiletypID, Bestelldatum, AID) VALUES 
							      (getBestManufacturer(part), NEW.WID, part, now(), NEW.AID);
				END LOOP;
			END LOOP;
		ELSE --JA
			--Iteriere über benötigte Teile
			FOR part IN (SELECT TeiletypID FROM Modellteile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID))
			LOOP
				
				--Anzahl wieoft Teil gebraucht wird.
				neededParts:=(SELECT Anzahl*(SELECT Anzahl FROM Aufträge WHERE AID=NEW.AID) FROM ModellTeile WHERE Modell_ID=(SELECT Modell_ID FROM Aufträge WHERE AID=NEW.AID) AND TeiletypID=part);
				LOOP
					IF(neededParts=0) THEN EXIT; END IF;
					--Bestelle die Teile
					INSERT INTO bestellt (HID, WID, TeiletypID, Bestelldatum, AID) VALUES 
							      (getBestManufacturer(part), NEW.WID, part, now(), NULL);
					--Setze bei genau einem Teil des benötigten Typs den Auftragsstatus
					UPDATE Autoteile SET AID=NEW.AID FROM (SELECT TeileID FROM Autoteile WHERE TeiletypID=part AND AID IS NULL ORDER BY ID ASC LIMIT 1) AS alias;
				END LOOP;
			END LOOP;
			-- Es sind alle Teile da, wird irgendein auftrag gerade aufgeführt? Wenn nein dann führe diesen hier aus.
			IF(NOT EXISTS (SELECT * FROM Werksaufträge WHERE Status='IN_BEARBEITUNG' AND WID=NEW.WID)) THEN
				UPDATE Werksaufträge SET Status='IN_BEARBEITUNG' WHERE WID=NEW.WID AND AID=NEW.AID;
			END IF;
		END IF;	
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;

CREATE TRIGGER onInsertWerksaufträge AFTER INSERT ON Werksaufträge FOR EACH ROW EXECUTE PROCEDURE insertInJobs();
