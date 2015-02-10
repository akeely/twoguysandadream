<?php
# script to generate an auction page

#check for sessions and get globals
include("my_sessions.php");
#TEMPORARY until sessions written
#$id = FALSE;
$login_extend_time = 180;

if($user) {
    header("Location: http://www.zwermp.com/cgi-bin/fantasy/php/fantasy_main_index.htm");
}

?>

<HTML>
<HEAD>
<TITLE>Team Entry Page</TITLE>

<script language="JavaScript">
<!--
function pswd_checker()
{
  if (entry_form.TEAM_PASSWORD.value == '')
  {
    alert("Please enter a password")
    return (false);
  }

  if (entry_form.TEAMS.value == 'Select Your Team')
  {
    alert("Please select a Team")
    return (false);
  }

  return (true);
}
-->
</script>

<LINK REL=StyleSheet HREF="style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<h2 align=center><u>Team Page</u></h2>

<br><br>
<p align=center>Click to see the <A href="rules.htm" target="rules">rules</a>.
<br><br>

<form name="entry_form" action="checkPSWD.php" method="post" onsubmit="return pswd_checker()">

<p align=center>
<a name="BIDDING"><b>Sign In:</b></a>
<table frame="box" border=3>
  <tr>
    <td align=middle>Your Team Name</td>
    <td align=middle>Your Team Password</td>
  </tr>
    <tr>
      <td align=middle>
        <select name="TEAMS">

<?php

$def = "Select Your Team";

# Connect to password database
$dbh=mysql_connect ("localhost", "doncote_draft", "draft") or die ('I cannot connect to the database because: ' . mysql_error());
mysql_select_db ("doncote_draft");

$table = "passwd";
$sth = mysql_query("SELECT * FROM $table");


while ($row = mysql_fetch_array($sth))
{
  $owner = $row['name'];
  if (strcmp($owner,$def) == 0)
  {
    $check = "selected";
  }
  else
  {
    $check = "";
  }
  echo "\t<option value=\"$owner\" $check>$owner</option>\n";
}

mysql_close($dbh);

echo <<<EOM

         </option>
        </select>
      </td>
      <td align=middle>
        <input type="password" name="TEAM_PASSWORD">
      </td>
    </tr>
</table>

<br>

<input type="reset" value="Clear The Forms" id=reset1 name=reset1> 
<input type="submit" value="Enter!" id=submit1 name=submit1>
<br><br>
<b>Note:</b> For security purposes, if your session is inactive (ie. you do not change pages, make bids, etc.)<br>for more than $login_extend_time minutes, you will be prompted to sign in again.<br>This allows the system to confirm your team indentity for transactions.
<br><br>
Also, Please remember to <b>log out</b> of the system when finished - it makes it easier for us.
</form>
</p>    

</BODY>
</HTML>

EOM;
?>
