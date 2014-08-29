--Konsistenztrigger 
 
--1. Die Werksid bei Werksarbeiter und Teilelagerarbeiter darf nicht NULL sein bei Update oder Insert
CREATE FUNCTION checkWerksid() RETURNS TRIGGER AS
	$$ BEGIN
		IF(NEW.wid IS NULL) THEN RAISE EXCEPTION 'Wid bei Insert/Update NULL';
		END IF; 
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;

	
CREATE TRIGGER validInsertWerksarbeiter BEFORE INSERT ON Werksarbeiter FOR EACH ROW EXECUTE PROCEDURE checkWerksid();
CREATE TRIGGER validUpdateWerksarbeiter BEFORE UPDATE ON Werksarbeiter FOR EACH ROW EXECUTE PROCEDURE checkWerksid();
CREATE TRIGGER validInsertTeilelagerarbeiter BEFORE INSERT ON Teilelagerarbeiter FOR EACH ROW EXECUTE PROCEDURE checkWerksid();
CREATE TRIGGER validUpdateTeilelagerarbeiter BEFORE UPDATE ON Teilelagerarbeiter FOR EACH ROW EXECUTE PROCEDURE checkWerksid();


--2.LKW-Fahrer müssen den Führerschein mindestens 3 Jahre besitzen.
CREATE FUNCTION checkLicenseDate() RETURNS TRIGGER AS
	$$ BEGIN
		IF(now() - NEW.führerscheindatum <= interval '3 years') THEN RAISE EXCEPTION 'Führerschein noch nicht lange genug';
		END IF;
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;
CREATE TRIGGER validInsertLKWFahrer BEFORE INSERT ON lkw_fahrer FOR EACH ROW EXECUTE PROCEDURE checkLicenseDate();
CREATE TRIGGER validUpdateLKWFahrer BEFORE UPDATE ON lkw_fahrer FOR EACH ROW EXECUTE PROCEDURE checkLicenseDate();

--3.Beschäftigungsbeginn muss in der Vergangenheit liegen
CREATE FUNCTION checkBeginn() RETURNS TRIGGER AS
	$$ BEGIN
		IF(NEW.beschäftigungsbeginn > now()) THEN RAISE EXCEPTION 'Beschäftigungsbeginn in der Zukunft';
		END IF; 
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;
CREATE TRIGGER validInsertMitarbeiter BEFORE INSERT ON mitarbeiter FOR EACH ROW EXECUTE PROCEDURE checkBeginn();
CREATE TRIGGER validUpdateMitarbeiter BEFORE UPDATE ON mitarbeiter FOR EACH ROW EXECUTE PROCEDURE checkBeginn();


