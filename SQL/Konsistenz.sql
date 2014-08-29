--Konsistenztrigger 
 
--1. Die Werksid bei Werksarbeiter und Teilelagerarbeiter darf nicht NULL sein bei Update oder Insert
CREATE FUNCTION checkWerksid() RETURNS TRIGGER AS
	$$ BEGIN
		IF(NEW.wid IS NULL) THEN 
			ROLLBACK TRANSACTION;			
			RAISE EXCEPTION 'Wid bei Insert/Update NULL';
		END IF; 
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;

	
CREATE CONSTRAINT TRIGGER validWerksarbeiter AFTER INSERT OR UPDATE ON Werksarbeiter INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE checkWerksid();
CREATE CONSTRAINT TRIGGER validTeilelagerarbeiter AFTER INSERT OR UPDATE ON Teilelagerarbeiter INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE checkWerksid();

--2.LKW-Fahrer müssen den Führerschein mindestens 3 Jahre besitzen.
CREATE FUNCTION checkLicenseDate() RETURNS TRIGGER AS
	$$ BEGIN
		IF(now() - NEW.führerscheindatum <= interval '3 years') THEN 
			ROLLBACK TRANSACTION;			
			RAISE EXCEPTION 'Führerschein noch nicht lange genug';
		END IF;
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;
CREATE CONSTRAINT TRIGGER validLkwFahrer AFTER INSERT OR UPDATE ON LKW_Fahrer INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE checkLicenseDate();

--3.Beschäftigungsbeginn muss in der Vergangenheit liegen
CREATE FUNCTION checkBeginn() RETURNS TRIGGER AS
	$$ BEGIN
		IF(NEW.beschäftigungsbeginn > now()) THEN 
			ROLLBACK TRANSACTION;			
			RAISE EXCEPTION 'Beschäftigungsbeginn in der Zukunft';
		END IF; 
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;
CREATE CONSTRAINT TRIGGER validWerksarbeiter AFTER INSERT OR UPDATE ON Mitarbeiter INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE checkBeginn();


