<?php

#check for sessions and get globals
include("my_sessions.php");
if(!$user) {
header('Location: http://www.zwermp.com/cgi-bin/fantasy/php/getTeam.php');
}

# files
#$image_path = 'http://www.zwermp.com/cgi-bin/fantasy/pics/';
#$bid_error_file = './error_logs/bid_errors.txt';
#$team_error_file = './error_logs/team_errors.txt';

?>
<HTML>
<HEAD>
<TITLE>Auction Page</TITLE>


<script language="JavaScript">
<!--
function createRequestObject() {

    var ro;
    try
    {
        // Firefox, Opera 8.0+, Safari
        ro = new XMLHttpRequest();
    }
    catch (e)
    {
       // Internet Explorer
       try
       {
          ro = new ActiveXObject("Msxml2.XMLHTTP");
       }
       catch (e)
       {
          try
          {
             ro = new ActiveXObject("Microsoft.XMLHTTP");
          }
          catch (e)
          {
             alert("ERROR: Your browser does not support AJAX!");
             return false;
          }
       }
    }
    return ro;
}
-->
</script>


<script language="JavaScript">
<!--
   var http = createRequestObject()
-->
</script>


<script language="JavaScript">
<!--
var ourInterval = setInterval("table_loop()", 6000);
-->
</script>


<script language="JavaScript">
<!--
function pswd_checker(mysize)
{
  if (bid_form.TEAM_PASSWORD.value == '')
  {
    alert("Please enter a password")
    return (false);
  }

  if (bid_form.TEAMS.value == 'Select A Team')
  {
    alert("Please select a Team")
    return (false)
  }

  // Check to make sure at least one new bid was made
  //  and that bid entries are numbers
  var bid_made = false
  var bids_ok = true;
  var check = '0123456789'
  for (counter = 1; counter < PLAYER_TABLE_1.rows.length; counter++)
  {
    counter2 = Math.floor(counter/2) + 1

    var text = "bid_form.NEW_BID_" + counter2 + ".value"
    var text2 = PLAYER_TABLE_1.rows[counter].cells[0].firstChild.nodeValue

    for (var i = 0; i < eval(text).length; i++)
    {
      var chr = eval(text).charAt(i);

      for (var j = 0; j < check.length; j++) 
      {
        if (chr == check[j])
        {
          break
        }

        // Should only reach here is a non-numeric entry is used
        if (j == (check.length - 1))
        {
          bids_ok = false
        }
      }

       if (bids_ok == false) break;
    }

    if ((eval(text) != 0) && (eval(text) != ''))
    {
      bid_made = true
    }
  }

  if (bid_made == false)
  {
    alert("You must make at least one new bid to submit this form!")
    return(false)
  }

  if (bids_ok == false)
  {
    alert("Your bids must only contain numbers!")
    return(false)
  }

  return(true)
}
-->
</script>


<script language="JavaScript">
<!--
function table_loop()
{

  var player_names = ""

  for (var i = 1; i < PLAYER_TABLE_1.rows.length; i++)
  { 
    player_names = player_names + PLAYER_TABLE_1.rows[i].cells[0].firstChild.nodeValue + ";"
  }
  sndReq(bid_form.league.value + "," + player_names)

}
-->
</script>


<script language="JavaScript">
<!--
function sndReq(action) {
    http.open('GET','checkBids.pl?action='+action)
    http.onreadystatechange = handleResponse
    http.send(null)
}
-->
</script>


<script language="JavaScript">
<!--
// Handle the response from the perl code
//  Writes new bids/bidders to the table
function handleResponse() 
{
    if(http.readyState == 4)
    {
        var response = http.responseText
        var update = new Array()
        var player_list = new Array()
        var players = new Array()
        var stat_list = new Array()
        var stats = new Array()

        update = response.split('|')
        if (update[0].length != 0)
        {
          player_list = update[0].split(';')
          for (var i = 0; i < (player_list.length); i++)
          {
            players[i] = player_list[i].split(',')
          }
        }

        var found = new Array(players.length)
        for (var i = 0; i<found.length; i++)
        {
          found[i] = 0
        }

        var count = 0
        for (var i = 1; i < PLAYER_TABLE_1.rows.length; i++)
        { 
          player_name = PLAYER_TABLE_1.rows[i].cells[0].firstChild.nodeValue

          for (var x = 0; x < players.length; x++)
          {
            if (players[x][0] == player_name)
            {
              found[x] = 1
              //If player has been won already, make his row red
              if (players[x][4] == "NA")
              {
                PLAYER_TABLE_1.rows[i].style.backgroundColor = "red"
                PLAYER_TABLE_1.rows[i].cells[2].firstChild.nodeValue = players[x][2]
                PLAYER_TABLE_1.rows[i].cells[3].firstChild.nodeValue = players[x][3]
                PLAYER_TABLE_1.rows[i].cells[4].firstChild.nodeValue = players[x][4]
                var input_num = i //Math.floor(i/2) + 1
                eval("bid_form.NEW_BID_" + input_num + ".disabled = true")
              }
              
              //If the leading bidder is this owner
              else if (players[x][3] == bid_form.team_id.value)
              {
                PLAYER_TABLE_1.rows[i].style.backgroundColor = "98FB98"
              }
              //If the bid has changed since last update
              else if (players[x][2] != PLAYER_TABLE_1.rows[i].cells[2].firstChild.nodeValue)
              {
                PLAYER_TABLE_1.rows[i].style.backgroundColor = "yellow"
                PLAYER_TABLE_1.rows[i].cells[2].firstChild.nodeValue = players[x][2]
                PLAYER_TABLE_1.rows[i].cells[3].firstChild.nodeValue = players[x][3]
                PLAYER_TABLE_1.rows[i].cells[4].firstChild.nodeValue = players[x][4]
              }
              else 
              {
                PLAYER_TABLE_1.rows[i].style.backgroundColor = "#EEEEEE"
              }

              break
            }
          }
          count++
        } // end for loop

        // add new rows, when needed
        for (var i = 0; i<found.length; i++)
        {
          if (found[i] == 0)
          {
            count++
            addRowToTable(players[i][0],players[i][1],players[i][2],players[i][3],players[i][4],count)
          }
        }

        //update total players input
        bid_form.total_players.value = count

        // update clock
        stat_table.rows[0].cells[0].innerHTML = "<b>Current Time</b><br>"+update[1]

        // update stats on side
        if (update[2].length != 0)
        {
          stat_list = update[2].split(';')
          for (var i = 0; i < (stat_list.length); i++)
          {
            stats[i] = stat_list[i].split(',')
          }
        }

        for (var i = 3; i < stat_table.rows.length; i++)
        { 
          stat_table.rows[i].cells[0].innerHTML = stats[i-3][0];
          stat_table.rows[i].cells[1].innerHTML = stats[i-3][1];
          stat_table.rows[i].cells[2].innerHTML = stats[i-3][2];
        }
    }
}

-->
</script>


<script language="JavaScript">
<!--
function addRowToTable(name,position,bid,bidder,time,num)
{
  var lastRow = PLAYER_TABLE_1.rows.length;
  // if there's no header row in the table, then iteration = lastRow + 1
  var row = PLAYER_TABLE_1.insertRow(lastRow);
 
  var cell1 = row.insertCell(0);
  var textNode1 = document.createTextNode(name);
  cell1.appendChild(textNode1);
  var cell2 = row.insertCell(1);
  var textNode2 = document.createTextNode(position);
  cell2.appendChild(textNode2);
  var cell3 = row.insertCell(2);
  var textNode3 = document.createTextNode(bid);
  cell3.appendChild(textNode3);
  var cell4 = row.insertCell(3);
  var textNode4 = document.createTextNode(bidder);
  cell4.appendChild(textNode4);
  var cell5 = row.insertCell(4);
  var textNode5 = document.createTextNode(time);
  cell5.appendChild(textNode5);

  var cell6 = row.insertCell(5);
  var textNode6 = document.createTextNode("Bid: ");
  var el  = document.createElement('input')
  var el2 = document.createElement('input')
  el.type = 'text'
  el.name = 'NEW_BID_' + num
  el.size = 4
  el.value = 0
  el2.type = 'hidden'
  el2.name = 'PLAYER_NAME_' + num
  el2.value = name
  cell6.appendChild(textNode6);
  cell6.appendChild(el);
  cell6.appendChild(el2);

  cell1.id= num + ' 0'
  cell1.rowspan=1
  cell1.valign="middle"
  cell2.id= num + ' 1'
  cell2.rowspan=1
  cell2.valign="middle"
  cell3.id= num + ' 2'
  cell3.rowspan=1
  cell3.valign="middle"
  cell4.id= num + ' 3'
  cell4.rowspan=1
  cell4.valign="middle"
  cell5.id= num + ' 4'
  cell5.rowspan=1
  cell5.valign="middle"
  cell6.id= num + ' 5'
  cell6.rowspan=1
  cell6.valign="middle"

  row.bgColor = "#FFFF00";
}
-->
</script>

<LINK REL=StyleSheet HREF="http://www.zwermp.com/cgi-bin/fantasy/style.css" TYPE="text/css" MEDIA=screen>

</HEAD>
<BODY onLoad="table_loop()">
<h2 align=center><u>Welcome to The Fantasy Auction!</u></h2>

<p align=center><a href="http://www.zwermp.com/cgi-bin/fantasy/fantasy_main_index.htm">Fantasy Home</a>
<br>

<iframe src="nav.htm" width="100%" height="60" scrollbars="no" frameborder="0"></iframe>

    Click to see the <A href="http://www.zwermp.com/cgi-bin/fantasy/rules.htm" target="rules">rules</a>.
    <br><br>
    </p>

    <form name="bid_form" action="http://www.zwermp.com/cgi-bin/fantasy/php/putBids.pl" method="post">


<?



####################
#
# Footer Print
#
####################

function Footer($league,$total_players,$team_name,$use_IP_flag)
{

if (strcmp($use_IP_flag,'yes') == 0)
{
echo <<<FOOTER

<br>
<div style="position: relative; left: 250; clear:both;">
<a name="BIDDING"><b>Enter Bid(s) for Team $team_name</b></a>
<br>
<input type="hidden" name="TEAMS" value="$team_name">

FOOTER;

} # end if

else ## not using IP for bidder identification - must choose team and enter password
{

echo <<<FOOTER

<div style="position: relative; left: 250; clear:both;">

<a name="BIDDING"><b>Enter Bid(s) for Selected Team</a>
<br>
<table>
<tr>
<td align=middle>User Name</td>
<td align=middle>Password</td>
</tr>
<tr>
<td align=middle>
<select name="TEAMS">

FOOTER;

    ## Output each team name as an option in the pull-down - default to cookie team name if available
    # Connect to DB


    #Get Team List
    $sth = mysql_query("SELECT * FROM teams WHERE league = '$league'");

    while ($row = mysql_fetch_array($sth))
    {
        $tf_name = $row['name'];
        $tf_owner = $row['owner'];
        $check = "";
        if (strcmp($tf_name,$team_name) == 0)
        {
            $check = "selected";
        }

        PrintOwner($tf_owner,$tf_name,$check);
    }

echo <<<FOOTER

</select>
</td>
<td align=middle>
<input type="password" name="TEAM_PASSWORD">
</td>
</tr>
</table>

FOOTER;

} # end else

echo <<<FOOTER

<input type="submit" value="Submit My Bid!" id=submit1 name=submit1>
<input type="reset" value="Clear The Forms" id=reset1 name=reset1>
<br>
Note: If your bids are too low they will not be recorded.

<input type="hidden" id=total name="total_players" value="$total_players">
<input type="hidden" id=league name="league" value="$league">
<br>
</div>

</form>
</p>

</BODY>
</HTML>

FOOTER;

}


######################
#
# Add Player
#
######################


function AddPlayer($name,$pos,$bid,$bidder,$time,$count)
{


echo <<<EOM

<tr>

<td id="$count 0" rowspan=1 valign="middle">$name</td>
<td id="$count 1" rowspan=1 valign="middle">$pos</td>
<td id="$count 2" rowspan=1 valign="middle">$bid</td>
<td id="$count 3" rowspan=1 valign="middle">$bidder</td>
<td id="$count 4" rowspan=1 valign="middle">$time</td>
<td id="$count 5" rowspan=1 valign="middle">Bid: <input type="text" name="NEW_BID_$count" size=13 value=0><input type="hidden" name="PLAYER_NAME_$count" value="$name"></td>
</tr>
EOM;

}

######################
#
# Print Hidden
#
######################


function PrintHidden($field1)
{

echo <<<EOM

<input type="hidden" name="team_id" value="$field1">

EOM;

}



######################
#
# Print Owner
#
######################



function PrintOwner($owner,$name,$check)
{

echo <<<EOM

<option value="$owner" $check>
$name
</option>

EOM;

}



######################
#
# List Error
#
######################


function ListError($message)
{
echo <<<EOM

$message

EOM;

}


##############
#
# Main Function
#
##############

# variables for players
#my @name;
#my @pos;
#my @bid;
#my @bidder;
#my @time;
#my @team;
#my @ez_time;
$count = 0;
$total_players = 0;


## Connect to the DB
$dbh=mysql_connect ("localhost", "doncote_draft", "draft") or die ('I cannot connect to the database because: ' . mysql_error());
mysql_select_db ("doncote_draft");

#Get League Data
$sth = mysql_query("SELECT * FROM leagues WHERE name = '$league'");
list($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_start_time,$auction_end_time,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = mysql_fetch_array($sth);

$auction_start_time = $auction_start_time - $TZ_offset;
$auction_end_time = $auction_end_time - $TZ_offset;


$players_auction_file = "auction_players";
$players_won_file = "players_won";
#$messagefile = "./text_files/message_board_$league.txt";

# DB-style
$sth = mysql_query("SELECT COUNT(*) FROM $players_auction_file WHERE league = '$league'");
$total_players = mysql_fetch_array($sth);

#time stuff.
list($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
$RealMonth = $Month + 1;
if($RealMonth < 10)
{
$RealMonth = "0" . $RealMonth;
}
if($Day < 10)
{
$Day = "0" . $Day; # add a leading zero to one-digit days
}
$Fixed_Year = $Year + 1900;
$time_string = "AM";
if($Hour >= 12)
{
$time_string = "PM";
}
if ($Minute < 10)
{
$Minute = '0' . $Minute;
}

$auction_string_hour = $Hour%12;
$auction_string = "$RealMonth/$Day - $auction_string_hour:$Minute $time_string";


echo "    <input type=\"hidden\" name=\"team_id\" value=\"$team\">";


# open(MESSAGES, "<$bid_error_file");
# flock(MESSAGES,1);
# @LINES=<MESSAGES>;
# chomp (@LINES);
# close(MESSAGES);
# $SIZE=@LINES;

#only print the messages if they are meant for this user (or if we are not tracking who the user is)
# for ($x=0;$x<$SIZE;$x++)
# {
# #print any errors
# ($myteam, $myleague, $myline) = split(';',$LINES[$x]);
# if ((($myleague eq $league) & ($myteam eq $team) & ($use_IP_flag eq 'yes')) | #($use_IP_flag eq 'no'))
# {
# ListError($myline);
# }
# }

##############################
# Display teams with money remaining
##############################


$sth = mysql_query("Select count(*) from teams where league='$league'");
list($team_count) = mysql_fetch_array($sth);



# Display time, remaining budgets and roster spots



#<div style="position: relative; left: 20;">

echo <<<EOM

 </table>

</div>



<div style="float: left;">

    <table id="stat_table" style="font-size:80%;">

      <tr align=center><td colspan=3><b>Current Time</b>$time_string</td></tr>

      <tr bgcolor="#5599cc"><td colspan=3></td></tr>

      <tr>

        <td><b>Team</b></td>

        <td><b>Money</b></td>

        <td><b>Roster Spots</b></td>

      </tr>



EOM;



for ($x=0; $x<$team_count; $x++)

{



echo <<<EOM

      <tr>

        <td></td>

        <td></td>

        <td></td>

      </tr>

EOM;



}



echo <<<EOM

  </table>

 </div>

EOM;




################################
# End teams table
################################






## Set up player auction table
echo <<<TBL


<div id='main_div' style="position: relative; left: 10;">
  <table cellpadding=5 frame="box" id="PLAYER_TABLE_1">
  <tr>
      <th>Player</th>
      <th>Position</th>
      <th>High Bid</th>
      <th>Bidder</th>
      <th>End Time</th>
      <th>Your Bid</th>
  </tr>

TBL;


## Trying to add players-won logic here . . .
$sth = mysql_query("SELECT * FROM $players_auction_file WHERE league = '$league'");

$player_print_count = 1;

while (list($name,$pos,$bid,$bidder,$time,$ez_time,$league_t) = mysql_fetch_array($sth))
{
$time_over = 0;
#list($end_month,$end_day,$end_hour,$end_minute) = split(':',$ez_time);
$end_time = $ez_time;

# If the player goes unclaimed, flag it
$player_claimed = 1;
if (strcmp($bidder,'<b>UNCLAIMED</b>') == 0)
{
$player_claimed = 0;
}

## CRAZY auction-done logic ... Removed time-strings - see if still works!!!!!
if( $current_time > $end_time )
{

$time_over = 1;

# in case our server is in a different time zone . . .
#$right_hour = $Hour + $TZ_offset;
#if($right_hour >= 0)
#{
#$right_hour = $right_hour%12;
#}

## If the time is over - no matter whether or not player was won, just DELETE him
mysql_query("DELETE FROM $players_auction_file WHERE name=$name AND league = '$league'");


if ($player_claimed == 1)
{
## Get owner name for winning team
$sth = mysql_query("SELECT * FROM teams WHERE name = '$bidder' AND league = '$league'");
list($tf_owner, $tf_name, $tf_league, $tf_adds, $tf_sport) = mysql_fetch_array($sth);
$sth->finish();



# DB-style
# update players won file
mysql_query("REPLACE INTO $players_won_file VALUES('$name','$pos','$bid','$bidder','$time','$ez_time','$league')");

## Update num_adds for winner
$tf_adds = $tf_adds+1;
mysql_query("Update teams set num_adds='$tf_adds' where name='$bidder' and league='$league'");

} #end if (player_claimed)

else
{
#if time is over but the player was not claimed, just remove him from the auction
# DB-style
$sth = mysql_query("DELETE FROM $players_auction_file WHERE name = '$name' AND league = '$league'");

#open(MSG, ">>$messagefile");
#flock(MSG,1);
#print MSG "<b>AUCTION ALERT</b>;$RealMonth/$Day/$Fixed_Year #($right_hour:$Minute $time_string EST);<b>$name was not claimed in the auction</b>\n";
#close(MSG);
}


} #end if (time_over)

#else
#{
#AddPlayer($name,$pos,$bid,$bidder,$time,$player_print_count);
#$player_print_count++;
#}

########################
# Else if the time is not over, do nothing - leave players in the database
########################

} #end for-loop


mysql_close($dbh);

print "</table>\n</div>";

Footer($league,($a_num-1), $team,$use_IP_flag);

?>