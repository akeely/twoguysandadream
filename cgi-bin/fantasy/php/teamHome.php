<?php
# script to generate an auction page

#check for sessions and get globals
include("my_sessions.php");
if(!$user) {
    header('Location: http://www.zwermp.com/cgi-bin/fantasy/php/getTeam.php');
}

#Get League Data
$dbh=mysql_connect ("localhost", "doncote_draft", "draft") or die ('I cannot connect to the database because: ' . mysql_error());
mysql_select_db ("doncote_draft");
$sth = mysql_query("SELECT * FROM leagues WHERE name = '$league'") or die ('Cannot access sessions table because: ' . mysql_error());
$row = mysql_fetch_array($sth);

$league_name = $row['name'];
$league_owner = $row['owner'];
$league_draftType = $row['draft_type'];
$draftStatus = $row['draft_status'];
$contractStatus = $row['contract_status'];
$categories = $row['categories'];
$league_positions = $row['positions'];
$max_members = $row['max_teams'];
$cap = $row['salary_cap'];
$auction_start_time = $row['auction_start'];
$auction_end_time = $row['auction_end'];
$auction_length = $row['auction_length'];
$bid_time_extension = $row['bid_time_ext'];
$bid_time_buffer = $row['bid_time_buf'];
$TZ_offset = $row['tz_offset'];
$login_extend_time = $row['login_ext'];
$use_IP_flag = $row['sessions_flag'];

# Crudely find out how many people are allowed per roster
if (strcmp($sport,'baseball') == 0)
{
  $max_players = 10; #default

  $test_positions = array("Util","Util2","Util3","Util_IN","Util_OF","SP2","SP3","RP2","RP3","P1","P2","P3","B1","B2","B3","B4","B5");
}
elseif (strcmp($sport_t,'football') == 0)
{
  $max_players = 6; #default

  $test_positions = array("QB2","QB3","RB2","RB3","WR2","WR3","TE2","OFF1","OFF2","K2","DEF2","B1","B2","B3","B4","B5","B6");
}

foreach ($test_positions as $pos)
{
  if (strstr($league_positions,$pos))
  {
    $max_players++;
  }
}


########################
#
# Header Print
#
########################

echo <<<EOM

<HTML>
<HEAD>
<LINK REL=StyleSheet HREF="style.css" TYPE="text/css" 
MEDIA=screen>
<TITLE>Your Team Page</TITLE>
</HEAD>
<BODY>

<h2 align=center><u>Welcome, $name</u></h2>

<p align=center><a href="fantasy_main_index.htm">Fantasy 
Home</a>

<iframe src="nav.htm" width="100%" height="60" scrollbars="no" frameborder="0"></iframe>

<p align=center>Click to see the <A href="rules.htm" 

target="rules">rules</a>.
<br><br>

<table align=center class=none>
<tr>

EOM;

######################
#
# Print Owner
#
######################

function PrintOwner($owner,$team)
{

echo <<<EOM
  <option value="$team"> 
  $team
EOM;

}


####################
#
# Footer Print
#
####################

function Footer($user)
{
  if (strcmp($user,$league_owner) == 0)
  {
echo <<<FOOTER

</form>
<tr>
 <td colspan=3 align=middle>Go to <a href="getTools.php" 

target="_top"><font color="blue">Commissioner Tools</font></a></td>
</tr>
</table>
</td>
</tr>
</table>
</p>

</BODY>
</HTML>

FOOTER;
  }
  else
  {
echo <<<FOOTER

</form>
</table>
</td>
</tr>
</table>
</p>

</BODY>
</HTML>

FOOTER;
  }
}


######################
#
# Print Player
#
######################


function PrintPlayer($name,$cost)
{

 if (strcmp($cost,'') == 0)
 {
   $name  = "    "; 
   $cost2 = "    ";
 }
 else
 {
   $cost2 = "\$$cost";
 }

echo <<<EOM

  <tr colspan=2>
   <td style="width: 175px; height:30px;">$name</td>
   <td>$cost2</td>
  </tr>

EOM;

}

######################
#
# Get Bidding
#
######################


function getBidding($total_spent,$league_t)
{

#   $dbh = mysql_connect ("localhost","doncote_draft","draft")
#                  or die ('I cannot connect to the database because: ' . mysql_error());
#   mysql_select_db ("doncote_draft");
  ######################################################
  ######################################################
  # Get the names and prices of the players this owner is bidding upon
  ######################################################
  ######################################################
  $count = 0;
  $auctionfile = "auction_players";
  $sth = mysql_query("SELECT * FROM $auctionfile WHERE team = '$team' AND league = '$league_t' ORDER BY price");

  while ($row = mysql_fetch_array($sth))
  {
     $name = $row['name'];
     $bid = $row['price'];
     $players2[] = array(name => $name, price => $bid );
    $count++;
  }   
#  mysql_close($dbh);

  $total_spent2 = 0;
  ###########################
  # Print the current team
  ###########################
  if($players2) {
     foreach($players2 as $member)
     {
       $name = $member['name'];
       $bid = $member['price'];
       PrintPlayer($name,$bid);
       $total_spent2 += $bid;
     }
   }

  global $cap;
  $money_left = $cap - $total_spent - $total_spent2;
  if ($count == 0)
  {
    PrintPlayer('No Players','0');
    PrintPlayer('<b>Available Funds</b>',"<b>$money_left</b>");
  }
  if (strcmp($league_draftType,  'Auction') == 0)
  {
     PrintPlayer('<b>Total Bidding</b>',"<b>$total_spent2</b>");
     PrintPlayer('<b>Available Funds</b>',"<b>$money_left</b>");
  }

} # End getBidding


######################
#
# Print Target
#
######################


function PrintTarget($target,$limit,$auto,$number)
{
  echo "   <tr>\n";

  if (strcmp($auto,"yes") == 0){
      echo "    <td><input type=checkbox name='auto$number' checked></td>";
  }
  else {
      echo "    <td><input type=checkbox name='auto$number'></td>";
  }

echo <<<EOM

      <td>$target
      <input type=hidden name="name$number" value="$target"></td>
      <td align=center>\$$limit
      <input type=hidden name="limit$number" value="$limit"></td>
     </tr>

EOM;

} ## End PrintTarget


######################
#
# Print Trade Offer
#
######################


function PrintTradeOffer($isOwner,$message,$num)
{
  if($isOwner == 0)
  {
     $forms = "<input type=radio name=decision$num value=yes>Accept<br>\n<input type=radio name=decision$num value=no>Decline<br>\n";
  }
  elseif($isOwner == 1)
  {
     $forms = "<input type=radio name=decision$num value=cancel>Cancel<br>\n";
  }

echo <<<EOM

<tr>
 <td>
   <input type=hidden name=trade_num value=$num>
   $forms
 </td>
 <td>
  $message
 </td>
</tr>

EOM;

} # End PrintTradeOffer

######################
#
# Get Trades
#
######################


function getTrades()
{
#########################
# MOVE TO mySQL!!!
#########################
#  open(TRADES,"<$tradefile");
#  flock(TRADES,1);
#  $count = 0;
#  foreach $line (<TRADES>)
#  { 
#   chomp($line);  
#   ($receiver,$proposer,$numgets,$costgets,$playerstoget,$numgives,$costgives,$playerstogive) = 

#   split(';',$line);
 
#   $playerstoget =~ s/:/ and /g;
#   $playerstogive =~ s/:/ and /g;
#   $owner = 2;  #default
#   if($receiver eq $team_t)
#   {
#     $owner = 0;  #not offered by you
#     $message = "$proposer has offered you a trade: $playerstogive for $playerstoget";
#     PrintTradeOffer($owner,$message,$count);
#   }

#   elseif($proposer eq $team_t)
#   {
#     $owner = 1;  #offered by you
#     $message = "You have offered $receiver a trade: $playerstogive for $playerstoget";
#     PrintTradeOffer($owner,$message,$count);
#   }
#  $count++; # increment whether or not the trade involves the user Team
#  }
#  close(TRADES);

} # End getTrades

######################
#
# Print Trade Messages
#
######################

function PrintTradeMessages($message,$num)
{

echo <<<EOM
      
<tr>
<td align=center width=10%><input type=radio name="msg_decision$num" value=cancel>Clear</td>       
<td align=center>$message</td>      
</tr>

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

$message<br>

EOM;

}

##########################################
#
#      Main Function
#
##########################################

$auctionfile = "auction_players";
$playerfile = "players_won";
# MOVE TO mySQL!!!
#$tradefile = "./text_files/trades_$league_t.txt";
#$trade_messages = "./text_files/trade_messages_$league_t.txt";
#$targets = "./text_files/player_targets_$league_t.txt";

##
##
## Trade Proposal Stuff 
##
##
################################

# Make column for Trade Window

echo <<<EOM
<td class=none>
<table frame=box cellpadding=5 bordercolor=#666666 border=3 style="table-layout: fixed; WIDTH: 

205px; HEIGHT:125px; overflow: auto; overflow-x: hidden; overflow-y:scroll">
  <tr align=center>
   <td>
    <b>Propose a Trade</b>
   </td>
  </tr>
 <tr align=center>
  <td>
  <form action="getTrade.php" method="post"> 
  <select name="TEAMS" ID="Select1">
EOM;


#Get Team List
$sth = mysql_query("SELECT * FROM teams WHERE league = '$league'");

while ($row = mysql_fetch_array($sth))
{
  $tf_name = $row['name'];
  $tf_owner = $row['owner'];
  if (strcmp($tf_name,$team) != 0)
  {
    PrintOwner($tf_owner,$tf_name);
  }
}

echo <<<EOM
 </select>
  <br><br>
  <input type=submit value="Make a Trade!">
</td>
 </tr>
</form>
</table>
</td>

<td colspan=2 class=none>

<div style="WIDTH: 580px; HEIGHT: 125px; overflow: auto; overflow-x: hidden; overflow-y:auto;">
<form action="doTrades.php" method="post">

<table cellpadding=5 style="table-layout: auto; WIDTH: 580px; Height: 125px">
      <tr align=center>
      <td width=10%>
       <input type=submit value="Update">
      </td>
      <td colspan=2 align=center>
       <b>Trade News</b>
      </td>
      </tr>
EOM;

##
##
## Print any relevant trade messages
##
######################
# MOVE TO mySQL!!!
#  open(TRADEM,"<$trade_messages");
#  flock(TRADEM,1);
#  $count = 0;
#  foreach $line (<TRADEM>)
#  {
#    chomp($line); 
#    ($owner,$message) = split(';',$line);
#    if ($team_t eq $owner)
#    {
#      PrintTradeMessages($message,$count);
#    }
#    $count++;
#  }
#  close(TRADEM);

##
##
## Get current trades involving this owner
##
######################
getTrades(); 

echo <<<EOM

 </form>
 </table>
 </div>
 </td>
 </tr>

EOM;


#######################################
##
## Get the names and prices of the players this owner has won
##
#######################################
 #find number of players won by this owner, and the number under bid
 $count = 0;
 $sth = mysql_query("SELECT * FROM $playerfile WHERE team = '$team' AND league = '$league' ORDER BY price DESC");

 while ($row = mysql_fetch_array($sth))
 {
   $name = $row['name'];
   $bid = $row['price'];
   $players[] = array(name => $name, price => $bid);
   $count++;
 }   

## Make Table for Owner's Current Roster

echo <<<EOM

<tr>
<td valign=top style="Position: relative; top: 30" class=none>
<table frame=box cellpadding=5 bordercolor=#666666 border=3 style="table-layout: auto; WIDTH: 

205px; Height: 200px; overflow: auto; overflow-x: hidden; overflow-y:scroll;">
  <tr align=center>
   <td colspan=2>
    <b>Your Current Team</b>
   </td>
  </tr>

EOM;

$total_spent = 0;
$tic = 0;
###########################
# Print the current team
###########################
if($players) {
   foreach ($players as $member)
   {
     $name = $member['name'];
     $bid = $member['price'];
     PrintPlayer($name,$bid);
     $total_spent += $bid;
     $tic++;
   }
}


for($z=$tic;$z<$max_players;$z++)
{
  PrintPlayer(' ',' ');
}
PrintPlayer('<b>Total Cost</b>',"<b>$total_spent</b>");


##################################
####
#### END Players Won Roster Stuff
####
##################################

echo <<<EOM

 </table>
 </td>

<td valign=top style="Position: relative; left: 30; top: 30" class=none>
<table frame=box cellpadding=5 bordercolor=#666666 border=3 style="table-layout: auto; width: 205px;">
   <tr align=center>
    <td colspan=2>
     <b>Leading Bids</b>
    </td>
   </tr>
EOM;

##
##
## Get the info for players that the owner is currently bidding on
##
##
########################
getBidding($total_spent,$league);

## End table for Bidding Targets
#
## Make column for Player Targets
echo <<<EOM

</table>
</td>

<td valign=top style="Position: relative; left: 30; top: 30" class=none>
<table frame='box' cellpadding=5 bordercolor=#666666 border=3 style="table-layout: auto; width:300px;">
 <tr align=center>
  <td colspan=3>
   <b>Target Players</b>
  </td>
 </tr>
EOM;

##
##
## Player Targets Stuff
##
##
###########################

$available_space = $max_players - $tic;
echo <<<FORM
<form action="getTarget.php" method="post">
<tr>
 <td align=center colspan=2>Roster Space: <b>$available_space</b></td>
 <td align=center><input type="submit" value="Add Target" size = 18></td>
</tr>
</form>
<tr> 
  <tr>
   <td align=center><b>Auto-Bid</b></td>
   <td align=center><b>Name</b></td>
   <td align=center><b>Price Limit</b></td>
  </tr>

<form action="addTarget.php" method="post">

FORM;

# MOVE TO mySQL!!!
#open(TARGETS,"<$targets");
#flock(TARGETS,1);
# $my_count = -1;
# foreach $line (<TARGETS>)
# {
#  chomp($line);
#  ($owner,$target,$limit,$auto) = split(';',$line);
#  if ($owner eq $team_t)
#  {
#    $my_count++;
#    PrintTarget($target,$limit,$auto,$my_count);
#  }
#}
#close(TARGETS);

echo <<<EOFORM

  <tr>
    <td colspan=3>
      <input type=hidden name=total value="$my_count">
      <center><input type=submit value="Update AutoBid"></center>
    </td>
  </tr>

EOFORM;

## End File
Footer($user);

mysql_close($dbh);

?>