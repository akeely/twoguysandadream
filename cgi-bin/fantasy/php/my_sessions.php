<?php
if(!isset($_COOKIE["SESS_ID"]))
{
    $user = FALSE;
}
else
{
     $id = $_COOKIE["SESS_ID"];

     $dbh=mysql_connect ("localhost", "doncote_draft", "draft") or die ('I cannot connect to the database because: ' . mysql_error());
     mysql_select_db ("doncote_draft");

     $sth = mysql_query("SELECT * FROM sessions WHERE sess_id = '$id'") or die ('Cannot access sessions table because: ' . mysql_error());
     $row = mysql_fetch_array($sth);
     
     if(strcmp($row["IP"],$_SERVER['REMOTE_ADDR']) == 0)
     {
           $user = $row['owner'];
           $team = $row['team'];
           $sport = $row['sport'];
           $league = $row['league'];
      }
      else
      {
           $user = FALSE;
      }
     mysql_close($dbh);
}

?>
