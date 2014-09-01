<?php
//Connect to Database
$host        = "host=127.0.0.1";
$port        = "port=5432";
$dbname      = "dbname='Happy Car'";
$credentials = "user=postgres"; //"user=postgres password=1234" also possible here.
$db = pg_connect( "$host $port $dbname $credentials");
if(!$db){
	echo "Error : Unable to open database\n";
} /*else {
	echo "Opened database successfully\n";
}*/
					
$NUM_RAND_ENTRYS=500;

$FIR_NAME_POOL=array("Sebastian", "Petra", "Sabine", "Alfred", "Gregor", "Maike", "Sibille", "Achim", "Bernard", "Gisela", "Ferdinand", 			"Alfons", "Jack", "Ömer", "Sana", "Jens", "Mark", "Moritz", "Max", "Selina", "David", "Gustav", "Paula", "Roswitha", 				"Fred", "Donald", "Susanne", "Daria", "Heiko", "Robert", "Daniel", "Lukas", "Herbert", "Mickey", "Marko", "Anke", 				"Henriette", "Jim", "John", "Adolf", "Kilian", "Rob", "Steve", "Ingried", "Nadine", "Michelle", "Julian", "Phillipp", 				"Luca", "Maria", "Mara", "Klaus", "Bernd", "Fritz", "Frank", "Isaak", "Joshua", "Saskia", "Heino", "Heinz" );
$SEC_NAME_POOL=array("Müller", "Meier", "Schmidt", "Becker", "Meilleur", "Schumacher", "Swarowski", "Schmitt", "Gorbatschow", "Schröder", 				"von Dotzenforf", "Weiland", "Grübellall", "Simbaputsch", "Kabelung", "Viegeldung", "Reimsbach", "Trottlewitz", 			"Fanta", "Klingala", "Vogo", "Herrmans", "Schumann", "Duck", "Mouse", "Polo", "Grafenwalder", "Remsch", "Totenbach", 				"Gobbeldorf", "Hanswurst", "Somo", "Schlomo", "Heinrichs", "Altintop", "Ludolf", "Gerster", "Meisser", "Hinterbaum",
			"Kobbel", "Zumo", "Tronk", "Geigendorf", "Reichsbach", "Fernando", "Wisko", "Klasowski", "Ziegler", "Berlo", "Matze", 				"Singdorf", "Gobelkop", "Ginseng", "Fischburn", "Wateva");
$WORD_POOL=array("Ufa", "Klun", "Ga", "Re", "Ta", "Schma", "Kong", "Cola", "Mombo", "Ma", "Si", "Tra", "Fan", "Ret", "Bei", "Hap", "Sap", 				"Dap", "Kin", "Dim", "Bim", "Rum", "Dum", "Zum", "Faru", "Klalu", "Hip", "Hop", "Dopp", "Jus", "Era", "Mus", "Pöp", 				"Köp", "Döp", "Kla", "Sik", "Zack", "Not", "Tot", "Brot", "Sum", "Sim", "Sam", "Wer", "Wo", "Wie", "Was", "Kau", "De", 				"Tre", "Rei", "Pu", "Kä", "Schla", "Arb", "Chi", "Rau", "Mau", "Sau", "Zur", "Gib", "Ent", "Ver", "Kam", "Ge", "Ga", 				"Gen", "An", "Ver", "Be", "Kom", "Zut", "Wär", "Rims", "Ser", "Jus", "Her", "Von", "Da", "Die", "Er", "As", "Bu",
			"Lo", "Si", "Jed", "Fang", "Wi", "Du", "Ma", "Lo", "Rei", "Wax", "Def", "Stef", "Schei", "Schro", "Schrie", "Sam");

for($i=0; $i<20; $i++){
	pg_query($db, "INSERT INTO Werke (Name) VALUES ('".randString(rand(1,4))."')");
}
echo "Step 1 done!";
function randString($length){
	global $WORD_POOL;
	$randomString=$WORD_POOL[(rand(1,count($WORD_POOL))-1)];	
	for($i=0; $i<$length; $i++){
		$randomString.=strtolower($WORD_POOL[(rand(1,count($WORD_POOL))-1)]);
	}
	return $randomString;
}

$sql_person_query="INSERT INTO Personen (Vorname, Nachname, PLZ, Straße, Wohnort, Email, TelNr) VALUES ";

for($i=0; $i<$NUM_RAND_ENTRYS; $i++){
	$sql_person_query.="('".$FIR_NAME_POOL[(rand(1, count($FIR_NAME_POOL))-1)]."', "
			  	."'".$SEC_NAME_POOL[(rand(1, count($SEC_NAME_POOL))-1)]."', "
			 	."'".rand(0,9).rand(0,9).rand(0,9).rand(0,9).rand(0,9)."', "
				."'".randString(rand(2,4))."str. ".rand(1,1000)."', "
				."'".randString(rand(2,5))."', "
			."'".strtolower(randString(rand(2,4)))."@".strtolower(randString(rand(1,3))).".".strtolower(randString(0))."', '0"
				.rand(0,9).rand(0,9).rand(0,9).rand(0,9).rand(0,9).rand(0,9).rand(0,9).rand(0,9).rand(0,9)."')";
	if($i+1==$NUM_RAND_ENTRYS){
		$sql_person_query.=";";
	}else{
		$sql_person_query.=", ";
	}
}
echo "Step 2 done!";
$ret = pg_query($db, $sql_person_query);

$sql_worker_query="SELECT PID FROM Personen WHERE PID NOT IN (SELECT PID FROM Mitarbeiter FULL OUTER JOIN Kunden USING (PID)) ORDER BY RANDOM() LIMIT 1";


for($i=0; $i<$NUM_RAND_ENTRYS/2; $i++){
	global $sql_worker_query;
	$randPers=pg_query($db, $sql_worker_query);
	if(!$randPers){
		echo "Problem beim Erzeugen von zufälligen Mitarbeitern (1)";
	}
	$row=pg_fetch_row($randPers);
	$date=rand(time()-63113851, time());
	$randWorker=pg_query($db, "INSERT INTO Mitarbeiter VALUES (".$row[0].", '".date('Y-m-d', $date)."', ".rand(850, 3750).", NULL) RETURNING PID");
	$raw=pg_fetch_row($randWorker);	
		
	
	if(!$randWorker){
		echo "Problem beim Erzeugen von zufälligen Mitarbeitern (2)";
	}
 	switch($i%6){
		case 0:
			global $raw;			
			$werk=pg_query($db, "SELECT WID FROM Werke ORDER BY RANDOM() LIMIT 1");
			$werk=pg_fetch_row($werk);			
			pg_query($db, "INSERT INTO Werksarbeiter VALUES (".$raw[0].", ".$werk[0].")");
			break;
		case 1:
			global $raw;			
			$license_date=date('Y-m-d',rand(time()-315569260, time()-94670777));
			pg_query($db, "INSERT INTO LKW_Fahrer VALUES (".$raw[0].", '".				$license_date."')");							
			break;
		case 2:
			global $raw;
			pg_query($db, "INSERT INTO Verwaltungsangestellte VALUES (".$raw[0].")");
			break;
		case 3:
			global $raw;
			$werk=pg_query($db, "SELECT WID FROM Werke ORDER BY RANDOM() LIMIT 1");
			$werk=pg_fetch_row($werk);			
			pg_query($db, "INSERT INTO Lagerarbeiter VALUES (".$raw[0].")");			
			pg_query($db, "INSERT INTO Teilelagerarbeiter VALUES (".$raw[0].", ".$werk[0].")");
			break;
		case 4:
			global $raw;
			pg_query($db, "INSERT INTO Lagerarbeiter VALUES (".$raw[0].")");
			pg_query($db, "INSERT INTO Autolagerarbeiter VALUES (".$raw[0].")");
			break;
	}	 	
}
echo "Step 3 done!";

for($i=0; $i<$NUM_RAND_ENTRYS/2; $i++){
	$randPers=pg_query($db, "SELECT PID FROM Personen EXCEPT (SELECT PID FROM ((Privatkunden FULL OUTER JOIN Kontaktpersonen USING (PID)) F
FULL OUTER JOIN Mitarbeiter USING (PID) )) 					LIMIT 1");
	if(!$randPers){
		echo "Problem beim Erzeugen von zufälligen Mitarbeitern (1)";
	}
	$randPers=pg_fetch_row($randPers);
	pg_query("INSERT INTO Kunden VALUES (".$randPers[0].", ".rand(1,1000).")");
	switch($i%2){
		case 0:
			global $randPers;
			$gh=pg_query($db, "INSERT INTO Großhändler (Firmenname, Straße, PLZ, Ort, Rabatt) VALUES ('"
						.randString(rand(2,6))."', '"
						.randString(rand(2,5))."str. "
						.rand(0,1000)."', '"
						.rand(0,9).rand(0,9).rand(0,9).rand(0,9).rand(0,9)."', '"
						.randString(rand(3,7))."', "
						.rand(0,25).") RETURNING GID");
			$gid=pg_fetch_row($gh);
			pg_query($db, "INSERT INTO Kontaktpersonen VALUES (".$randPers[0].", ".$gid[0].")");
			break;
		case 1:
			global $randPers;
			pg_query($db, "INSERT INTO Privatkunden VALUES (".$randPers[0].")");
			break;
	}
}

echo "Step 4 done!";

for($i=0; $i<$NUM_RAND_ENTRYS/4; $i++){
	$modell=pg_query($db, "INSERT INTO Modelle (Bezeichnung, Preis) VALUES ('".randString(rand(1,3))."', ".rand(9999,99999).") RETURNING Modell_ID");
	$modell=pg_fetch_row($modell);	
	$limit=rand(1,10);	
	for($j=0; $j<$limit; $j++){
 		$part=pg_query($db, "INSERT INTO Autoteiltypen (maxPreis, Bezeichnung) VALUES (".rand(100, 10000).", '".randString(rand(2, 			4))."') RETURNING TeiletypID");
		$part=pg_fetch_row($part);
		switch($i%5){
			case 0:
			pg_query($db, "INSERT INTO Motoren VALUES (".$part[0].", ".rand(35, 900).", ".rand(2000, 20000).", ".rand(1, 20).", 					'".randString(rand(2,4))."')");
			break;
			case 1:
			pg_query($db, "INSERT INTO Karosserien VALUES (".$part[0].", '".randString(rand(1,3))."', '".randString(rand(1,3))."', ".
				  rand(1,3).", ".rand(1,4).", ".rand(1,5).")");
			break;
			case 2:
			pg_query($db, "INSERT INTO Türen VALUES (".$part[0].", '".randString(rand(1,3))."', 'STANDARD')");
			break;
			case 3:
			pg_query($db, "INSERT INTO Fenster VALUES (".$part[0].", '".randString(rand(1,3))."', '".randString(rand(1,3))."')");
			break;
			case 4:
			pg_query($db, "INSERT INTO Reifen VALUES (".$part[0].", '".randString(rand(1,3))."', ".rand(8,30).", '"
				.randString(rand(1,3))."')");
			break;
		}
	}
	$hersteller=pg_query($db, "INSERT INTO Hersteller (Firmenname) VALUES ('".randString(rand(1,4))."') RETURNING HID");
	$hersteller=pg_fetch_row($hersteller);
	pg_query($db, "INSERT INTO produzieren VALUES (".$part[0].", ".$hersteller[0].", ".rand(200, 4000).", ".rand(1,8).")");
	pg_query($db, "INSERT INTO Modellteile VALUES (".$modell[0].", ".$part[0].", ".rand(1, 5).")");
}	

echo "Step 5 done!";

for($i=0; $i<$NUM_RAND_ENTRYS; $i++){
	pg_query($db, "INSERT INTO LKWs (Kaufdatum) VALUES ('".date("Y-m-d",time()-rand(0, 135893733))."')");
}

echo "Step 6 done!";

for($i=0; $i<$NUM_RAND_ENTRYS/3; $i++){
	$mitarbeiter=pg_query($db, "SELECT PID FROM Verwaltungsangestellte ORDER BY RANDOM() LIMIT 1");
	$mitarbeiter=pg_fetch_row($mitarbeiter);
	$kunde=pg_query($db, "SELECT PID FROM Kunden ORDER BY RANDOM() LIMIT 1");
	$kunde=pg_fetch_row($kunde);
	$modell=pg_query($db, "SELECT Modell_ID FROM Modelle ORDER BY RANDOM() LIMIT 1");
	$modell=pg_fetch_row($modell);
	$sql_job_query=pg_query($db, "INSERT INTO Aufträge (Modell_ID, Anzahl, KundenID, MitarbeiterID) VALUES (".$modell[0].", ".rand(1,5).","
					.$kunde[0].", ".$mitarbeiter[0].")");
	if(!$sql_job_query){
		echo "Auftrag einfügen fehlgeschlagen";
	}
}

echo "Step 7 done!";

for($i=0; $i<$NUM_RAND_ENTRYS/9 * 2; $i++){

	$auftrag=pg_query($db, "SELECT AID FROM Aufträge ORDER BY RANDOM() LIMIT 1");
	$auftrag=pg_fetch_row($auftrag);
	pg_query($db, "UPDATE bestellt SET Status='ARCHIVIERT' WHERE AID=".$auftrag[0]."");
	pg_query($db, "UPDATE Werksaufträge SET Status='ARCHIVIERT' WHERE AID=".$auftrag[0]."");
	pg_query($db, "DELETE FROM liefert WHERE AID=".$auftrag[0]."");
}

echo "Step 8 done!";

if(!$ret){
	echo pg_last_error($db);
	exit;
}
echo "FINISHED !!!!!";
?>
