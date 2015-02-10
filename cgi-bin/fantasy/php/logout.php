<?php

setcookie("SESS_ID", "", time()-3600);

$return = "http://www.zwermp.com/cgi-bin/fantasy/getTeam.pl"; 
$errors = "./error_logs/team_errors.txt";

$userAddr = $ENV{REMOTE_ADDR};
## Connect to sessions database
$dbh=mysql_connect ("localhost","doncote_draft","draft") or die ('I cannot connect to the database because: ' . mysql_error());
mysql_select_db ("doncote_draft");
$table = "sessions";
mysql_query("DELETE FROM $table WHERE sess_id = '$id'");
mysql_close($dbh);

header("Location: $return");

#open(FILE,">$errors");
#flock(FILE,2);
#print FILE "<b>Welcome to the Auction Web Site!<br><br></b>\n";
#close(FILE);

?>

