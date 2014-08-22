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
		status Teilestatus;
	BEGIN
		IF (OLD.aid IS NULL) THEN status='VERFÜGBAR'; 
				     ELSE status='RESERVIERT'; 
		END IF; 
		SELECT max(TeileID) INTO teilid FROM Autoteile;
		INSERT INTO Autoteile (TeileId ,TeiletypID, lagert_in, Lieferdatum, Status) VALUES (teilid+1,OLD.TeiletypID, OLD.WID, now(), status);
		
		RETURN OLD;
	END; $$ LANGUAGE plpgsql;
CREATE TRIGGER setOnCarPartsArrived BEFORE DELETE ON bestellt FOR EACH ROW EXECUTE PROCEDURE carPartsArrived();
