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

--2. LKW-Fahrer müssen den Führerschein mindestens 3 Jahre besitzen.
CREATE FUNCTION checkLicenseDate() RETURNS TRIGGER AS
	$$ BEGIN
		IF(now() - NEW.führerscheindatum <= interval '3 years') THEN 
			ROLLBACK TRANSACTION;			
			RAISE EXCEPTION 'Führerschein noch nicht lange genug';
		END IF;
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;
CREATE CONSTRAINT TRIGGER validLkwFahrer AFTER INSERT OR UPDATE ON LKW_Fahrer INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE checkLicenseDate();

--3. Beschäftigungsbeginn muss in der Vergangenheit liegen
CREATE FUNCTION checkBeginn() RETURNS TRIGGER AS
	$$ BEGIN
		IF(NEW.beschäftigungsbeginn > now()) THEN 
			ROLLBACK TRANSACTION;			
			RAISE EXCEPTION 'Beschäftigungsbeginn in der Zukunft';
		END IF; 
		RETURN NEW;
	END; $$ LANGUAGE plpgsql;
CREATE CONSTRAINT TRIGGER validWerksarbeiter AFTER INSERT OR UPDATE ON Mitarbeiter INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE checkBeginn();

--4. Wenn ein Auto auf ein LKW geladen wird, muss der Status auf LIEFERND gesetzt werden.
CREATE FUNCTION newDelivery() RETURNS TRIGGER AS
	$$ BEGIN
		UPDATE Autos SET Status='LIEFERND' WHERE kfz_id=NEW.kfz_id AND modell_id=NEW.modell_id;
		RETURN NEW;
	END;$$ LANGUAGE plpgsql;
	
CREATE CONSTRAINT TRIGGER validDelivery AFTER INSERT OR UPDATE ON liefert INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE newDelivery();

--5. Beim Einfügen eines neuen Auftrags muss der Mitarbeiter ein Verwaltungsangestellter sein.
CREATE FUNCTION newOrderCheckWorker() RETURNS TRIGGER AS
	$$ BEGIN
		IF(NOT EXISTS(SELECT 1 FROM Verwaltungsangestellte WHERE PID=NEW.MID)) THEN
			ROLLBACK TRANSACTION;
			RAISE EXCEPTION 'Der Mitarbeiter mit ID % ist kein Verwaltunsangestellter', NEW.MID;
		END IF;
	END; $$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER validInsertInLiefert AFTER INSERT ON Aufträge INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE newOrderCheckWorker();

--6. Beim Einfügen einer neuen Lieferung, muss der Mitarbeiter ein LKW-Fahrer sein.
CREATE FUNCTION newDeliveryCheckWorker() RETURNS TRIGGER AS
	$$ BEGIN
		IF(NOT EXISTS (SELECT 1 FROM LKW_Fahrer WHERE PID=NEW.MID)) THEN
			ROLLBACK TRANSACTION;
			RAISE EXCEPTION 'Der Mitarbeiter mit ID % ist kein LKW_Fahrer',NEW.MID;
		END IF;
	END; $$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER validInsertInDelivery AFTER INSERT ON liefert INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE newDeliveryCheckWorker();

--7. Beim Erstellen/Ändern eines neuen Modells muss es auch Hersteller für alle benötigten Teile geben
CREATE FUNCTION changeOnModell() RETURNS TRIGGER AS
	$$ BEGIN
		IF(EXISTS(SELECT 1 FROM Modellteile WHERE TeiletypID IN (SELECT TeiletypID FROM Autoteiltypen EXCEPT (Autoteiletypen JOIN produzieren USING TeiletypID)) THEN
			ROLLBACK TRANSACTION;
			RAISE EXCEPTION 'Nicht für alle benötigten Teile ist ein Hersteller verfügbar';
		END IF;
	END; $$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER validChangeInModellTeile AFTER INSERT OR UPDATE ON Modellteile INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE newOrderCheckWorker();
			
--8. Wenn ein Hersteller ein Teil löschen will, darf er nicht der einzige sein, der das Teil produziert.
CREATE FUNCTION changeOnOffer() RETURNS TRIGGER AS
	$$ BEGIN

		IF(NEW.Preis>(SELECT maxPreis FROM Autoteiletypen WHERE TeiletypID=NEW.TeiletypID)) THEN
			ROLLBACK TRANSACTION;
			RAISE EXCEPTION 'Ein Preis von % für das Teil mit der ID % ist zu teuer',NEW.Preis,NEW.TeiletypID;
		IF(NOT EXISTS(SELECT 1 FROM produziert WHERE TeiletypID=OLD.TeiletypID AND HID!=OLD.HID)) THEN
			ROLLBACK TRANSACTION;
			RAISE EXCEPTION 'Zur Zeit kann die Produktion des Teils mit ID % nicht eingestellt werden.', OLD.TeiletypID
		END IF;
	END; $$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER validChangeInProduction AFTER DELETE ON produziert INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE changeOnOffer();

