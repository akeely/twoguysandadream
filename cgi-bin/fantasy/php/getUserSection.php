<?php
include("my_sessions.php");

# script to generate a pull-down selection for owner's teams/leagues

# files
$team_error_file = "./text_files/team_errors.txt";
?>

<HTML>
<HEAD>
<LINK REL=StyleSheet HREF="style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>

<?php

if(!$user) {
echo <<<EOM

<center><b>Sessions error!</b> Please logout and log back in.</center>

EOM;
}
else {

echo <<<EOM
<p align=center>Visit your team clubhouse(s): 
<form action="putTeam.php" method="post" target="_top">

<table align=center>
 <tr>
  <td rowspan=2>
   <select name="user_sport">
EOM;

##############
#
# Main Function
#
##############

   $dbh=mysql_connect ("localhost", "doncote_draft", "draft") or die ('I cannot connect to the database because: ' . mysql_error());
   mysql_select_db ("doncote_draft");

  $sth = mysql_query("SELECT * FROM teams WHERE owner = '$user'");

  $teams_count = 0;
  $disable = "";
  while ($row = mysql_fetch_array($sth))
  {
    # ($tf_owner, $tf_name, $tf_league, $tf_adds, $tf_sport) = $sth->fetchrow_array()
    $tf_name = $row['name'];
    $tf_sport = $row['sport'];
    $tf_league = $row['league'];
    
    print "<option value='$tf_name:$tf_sport:$tf_league'>$tf_name - $tf_league</option>";
    $teams_count++;
  }

  mysql_close($dbh);

  if ($teams_count == 0)
  {
    print '<option value=no_team>No Teams Available</option>';
    $disable = 'disabled';
  }

echo <<<EOM
</select>
  </td>
  <td>
   <input type="submit" value="Go!" $disable>  
  </td>
 </tr>
</table>
</form>
</p>    
EOM;
} #logged in
?>
</BODY>
</HTML>


