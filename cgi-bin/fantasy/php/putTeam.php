<?php 

#check for sessions and get globals
include("my_sessions.php");
if(!$user) {
    header('Location: http://www.zwermp.com/cgi-bin/fantasy/php/getTeam.php');
}
else
{
   list($team_t,$sport_t,$league_t) = split(':',$_POST['user_sport']);
   
   $dbh=mysql_connect ("localhost", "doncote_draft", "draft") or die ('I cannot connect to the database because: ' . mysql_error());
   mysql_select_db ("doncote_draft");

   $sth = mysql_query("UPDATE sessions SET team = '$team_t', sport = '$sport_t', league = '$league_t' WHERE sess_id = '$id'");
   mysql_close($dbh);

   header("Location: http://www.zwermp.com/cgi-bin/fantasy/php/teamHome.php");
}

