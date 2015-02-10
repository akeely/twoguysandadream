#!/usr/bin/perl
use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use Nav_Bar;
use Session;
use DBTools;

## For UTF-8 characters
binmode(STDOUT, ":iso-8859-1");

# script to generate team's home page (pre-draft)

# files
$log = "/var/log/fantasy/teamHome_log.txt";
$team_error_file = "/var/log/fantasy/team_errors.txt";

my ($my_ip,$user,$pswd,$my_id,$team_t,$sport_t,$league_t) = checkSession();
my $dbh = dbConnect();

#Get League Data
$sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($league_name,$password,$league_owner,$league_draftType,$draftStatus,$contractStatus,$sport,$categories,$league_positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
$sth->finish();


# Crudely find out how many people are allowed per roster
if ($sport_t eq 'baseball')
{
  $max_players = 10; #default

  @test_positions = ("Util","Util2","Util3","Util_IN","Util_OF","SP2","SP3","RP2","RP3","P1","P2","P3","B1","B2","B3","B4","B5");
}
elsif ($sport_t eq 'football')
{
  $max_players = 6; #default

  @test_positions = ("QB2","QB3","RB2","RB3","WR2","WR3","TE2","OFF1","OFF2","K2","DEF2","B1","B2","B3","B4","B5","B6");

}

for (@test_positions)
{
  if ($league_positions =~ /$_/)
  {
    $max_players++;
  }
}


## ECW hack
my $sth_check_pos = $dbh->prepare("select count(1) from positions where league='$league_t'");
$sth_check_pos->execute();
$max_players += $sth_check_pos->fetchrow();
$sth_check_pos->finish();


########################
#
# Header Print
#
########################
sub Header()
{

  print "Cache-Control: no-cache\n";
  print "Content-type: text/html\n\n";

print <<HEADER;

<HTML>
<HEAD>
<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
<TITLE>Your Team Page</TITLE>
</HEAD>
<BODY>
<p align="center">

HEADER

}

########################
#
# Header1 Print
#
########################

sub Header1()
{

  my $is_commish = ($league_owner eq $user) ? 1 : 0;
  my $nav = Nav_Bar->new('My Team',"$user",$is_commish,$draftStatus,"$team_t");
  $nav->print();


print <<HEADER1;

<br><br>

<table align=center class=none>
<tr>

HEADER1

}

######################
#
# Print Owner
#
######################

sub PrintOwner($$)
{
  my $owner = shift;
  my $team = shift;

print <<EOM;
  <option value="$team"> 
  $team
EOM

}


####################
#
# Footer Print
#
####################

sub Footer($)
{
  my $user = shift;
  if ($user eq $league_owner)
  {
print <<FOOTER;

</form>
<tr>
 <td colspan=3 align=middle>Go to <a href="/cgi-bin/fantasy/getTools.pl" 

target="_top"><font color="blue">Commissioner Tools</font></a></td>
</tr>
</table>
</td>
</tr>
</table>
</p>

</BODY>
</HTML>

FOOTER
  }
  else
  {
print <<FOOTER;

</form>
</table>
</td>
</tr>
</table>
</p>

</BODY>
</HTML>

FOOTER
  }
}

########################
#
# PrintWelcome
#
########################

sub PrintWelcome($)
{
  
my $name = shift;  

print <<EOM;

<h2 align=center><u>Welcome, $name</u></h2>

EOM

}

######################
#
# Print Player
#
######################


sub PrintPlayer($$)
{
  my $name = shift;
  my $cost = shift;

 if ($cost =~ /^$/)
 {
   $name  = "    "; 
   $cost2 = "    ";
 }
 else
 {
   $cost2 = "\$$cost";
 }

print <<EOM;

  <tr colspan=2>
   <td style="width: 175px; height:30px;">$name</td>
   <td>$cost2</td>
  </tr>

EOM

}

######################
#
# Get Bidding
#
######################


sub getBidding($$)
{

  my $total_spent = shift;
  my $league_t = shift;

  ######################################################
  ######################################################
  # Get the names and prices of the players this owner is bidding upon
  ######################################################
  ######################################################
  $count = 0;
  $auctionfile = "auction_players";
  $sth = $dbh->prepare("SELECT name,price,team,time FROM $auctionfile WHERE team = '$team_t' AND league = '$league_t'")
          or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();

  $sth_get_name = $dbh->prepare("SELECT name FROM players WHERE playerid=?");

  while (($id,$bid,$bidder,$ez_time) = $sth->fetchrow_array())
  {
     $sth_get_name->execute($id) or die "Cannot execute: ". $sth_get_name->errstr();
     $name = $sth_get_name->fetchrow_array();
     
     @players2[$count] = ( 
     { name => $name, price => $bid });
    $count++;
  }   
  $sth->finish();
  ##$dbh->disconnect();


  ###########################
  #sort the bidding players by their price
  ###########################
  @ranked2 = sort { $a->{price} <=> $b->{price} } @players2;
  $total_spent2 = 0;
  ###########################
  # Print the current team
  ###########################
  foreach $member (@ranked2)
  {
    $name = $member->{name};
    $bid = $member->{price};
    PrintPlayer($name,$bid);
    $total_spent2 += $bid;
  }

  ## Apply cash +/- considerations from teams table
  my $sth_cash = $dbh->prepare("select money_plusminus from teams where name='$team_t' and league = '$league_t'");
  $sth_cash->execute();
  my $team_plusminus = $sth_cash->fetchrow();
  $sth_cash->finish();

  $money_left = $cap + $team_plusminus - $total_spent - $total_spent2;
  if ($count == 0)
  {
    PrintPlayer('No Players','0');
    PrintPlayer('<b>Available Funds</b>',"<b>$money_left</b>");
  }
  else
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


sub PrintTarget($$$$)
{
  my $target = shift;
  my $limit = shift;
  my $auto = shift;
  my $number= shift;

  print "   <tr>\n";

  if ($auto eq "yes"){
      print "    <td><input type=checkbox name='auto$number' checked></td>";
  }
  else {
      print "    <td><input type=checkbox name='auto$number'></td>";
  }

print <<EOM;

      <td>$target
      <input type=hidden name="name$number" value="$target"></td>
      <td align=center>\$$limit
      <input type=hidden name="limit$number" value="$limit"></td>
     </tr>

EOM

} ## End PrintTarget


######################
#
# Print Trade Offer
#
######################


sub PrintTradeOffer($$$)
{

  my $owner = shift;
  my $message = shift;
  my $num = shift;

  if($owner == 0)
  {
     $forms = "<input type=radio name=decision$num value=yes>Accept<br>\n<input type=radio name=decision$num value=no>Decline<br>\n";
  }
  elsif($owner == 1)
  {
     $forms = "<input type=radio name=decision$num value=cancel>Cancel<br>\n";
  }

print <<EOM;

<tr>
 <td>
   <input type=hidden name=trade_num value=$num>
   $forms
 </td>
 <td>
  $message
 </td>
</tr>

EOM

} # End PrintTradeOffer

######################
#
# Get Trades
#
######################


sub getTrades()
{

  open(TRADES,"<$tradefile");
  flock(TRADES,1);
  $count = 0;
  foreach $line (<TRADES>)
  { 
   chomp($line);  
   ($receiver,$proposer,$numgets,$costgets,$idstoget,$numgives,$costgives,$idstogive) = 

   split(';',$line);
 
   $proposer_names = '';
   $receiver_names = '';
   $sth_get_name = $dbh->prepare("SELECT name FROM players WHERE playerid=?");
   foreach (split(/:/,$idstoget))
   {
     $sth_get_name->execute($_);
     $proposer_names .= $sth_get_name->fetchrow() . ':';
   }
   foreach (split(/:/,$idstogive))
   {
     $sth_get_name->execute($_);
     $receiver_names .= $sth_get_name->fetchrow() . ':';
   }
   chop($proposer_names);
   chop($receiver_names);
   $proposer_names =~ s/:/ and /g;
   $receiver_names =~ s/:/ and /g;

   $owner = 2;  #default
   if($receiver eq $team_t)
   {
     $owner = 0;  #not offered by you
     $message = "$proposer has offered you a trade: $receiver_names for $proposer_names";
     PrintTradeOffer($owner,$message,$count);
   }

   elsif($proposer eq $team_t)
   {
     $owner = 1;  #offered by you
     $message = "You have offered $receiver a trade: $receiver_names for $proposer_names";
     PrintTradeOffer($owner,$message,$count);
   }
   $count++; # increment whether or not the trade involves the user Team
  }
  close(TRADES);

} # End getTrades

######################
#
# Print Trade Messages
#
######################

sub PrintTradeMessages($$)
{

  my $message = shift;
  my $num = shift;

print <<EOM;
      
<tr>
<td align=center width=10%><input type=radio name="msg_decision$num" value=cancel>Clear</td>       
<td align=center>$message</td>      
</tr>

EOM

}

######################
#
# List Error
#
######################


sub ListError($)
{
  my $message = shift;

print <<EOM;

$message<br>

EOM

}

##########################################
#
#      Main Function
#
##########################################

# variables for players
my $team;
my $timer;
my $entry;
my $owner;
my $auto;


$playerfile = "players_won";
$players_file = "players";
$tradefile = "/var/log/fantasy/trades_$league_t.txt";
$trade_messages = "/var/log/fantasy/trade_messages_$league_t.txt";
$targets = "/var/log/fantasy/player_targets_$league_t.txt";


Header();
#PrintWelcome($team_t);
Header1();

##
##
## Trade Proposal Stuff 
##
##
################################

# Make column for Trade Window

print <<EOM;
<td class=none>
<table frame=box cellpadding=5 bordercolor=#666666 border=3 style="table-layout: fixed; WIDTH: 205px; HEIGHT:125px; overflow: auto; overflow-x: hidden; overflow-y:scroll">
  <tr align=center>
   <td>
    <b>Propose a Trade</b>
   </td>
  </tr>
 <tr align=center>
  <td>
  <form action="/cgi-bin/fantasy/getTrade.pl" method="post"> 
  <select name="TEAMS" ID="Select1">
EOM


#Get Team List
$sth = $dbh->prepare("SELECT * FROM teams WHERE league = '$league_t'")
     or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();

while (($tf_owner, $tf_name, $tf_league, $tf_adds, $tf_sport, $tf_plusminus) = $sth->fetchrow_array())
{
  if ($tf_name ne $team_t)
  {
    PrintOwner($tf_owner,$tf_name);
  }
}
$sth->finish();

print <<EOM;
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
<form action="/cgi-bin/fantasy/doTrades.pl" method="post">

<table cellpadding=5 style="table-layout: auto; WIDTH: 580px; Height: 125px">
      <tr align=center>
      <td width=10%>
       <input type=submit value="Update">
      </td>
      <td colspan=2 align=center>
       <b>Trade News</b>
      </td>
      </tr>
EOM

##
##
## Print any relevant trade messages
##
######################
  open(TRADEM,"<$trade_messages");
  flock(TRADEM,1);
  $count = 0;
  foreach $line (<TRADEM>)
  {
    chomp($line); 
    ($owner,$message) = split(';',$line);
    if ($team_t eq $owner)
    {
      PrintTradeMessages($message,$count);
    }
    $count++;
  }
  close(TRADEM);

##
##
## Get current trades involving this owner
##
######################
getTrades(); 

print <<EOM;

 </form>
 </table>
 </div>
 </td>
 </tr>

EOM


#######################################
##
## Get the names and prices of the players this owner has won
##
#######################################
 #find number of players won by this owner, and the number under bid
 $count = 0;
 $sth = $dbh->prepare("SELECT name,price,team,time FROM $playerfile WHERE team = '$team_t' AND league = '$league_t'")
          or die "Cannot prepare: " . $dbh->errstr();
 $sth->execute() or die "Cannot execute: " . $sth->errstr();

 $sth_get_name = $dbh->prepare("SELECT name FROM $players_file WHERE playerid=? AND sport='$sport'");

 while (($id,$bid,$bidder,$ez_time) = $sth->fetchrow_array())
 {
   $sth_get_name->execute($id) or die "Cannot execute: ". $sth_get_name->errstr();
   $name = $sth_get_name->fetchrow();

   @players[$count] = ( 
   { name => $name, price => $bid });
   $count++;
 }   
 $sth->finish();


## Make Table for Owner's Current Roster

print <<EOM;

<tr>
<td valign=top style="Position: relative; top: 30" class=none>
<table frame=box cellpadding=5 bordercolor=#666666 border=3 style="table-layout: auto; WIDTH: 205px; Height: 200px; overflow: auto; overflow-x: hidden; overflow-y:scroll;">
  <tr align=center>
   <td colspan=2>
    <b>Your Draft Team</b>
   </td>
  </tr>

EOM

###########################
#sort the players by their price
###########################
@ranked = sort { $b->{price} <=> $a->{price} } @players;
$total_spent = 0;
$tic = 0;
###########################
# Print the current team
###########################
foreach $member (@ranked)
{
  $name = $member->{name};
  $bid = $member->{price};
  PrintPlayer($name,$bid);
  $total_spent += $bid;
  $tic++;
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

print <<EOM;

 </table>
 </td>

<td valign=top style="Position: relative; left: 30; top: 30" class=none>
<table frame=box cellpadding=5 bordercolor=#666666 border=3 style="table-layout: auto; width: 205px;">
   <tr align=center>
    <td colspan=2>
     <b>Leading Bids</b>
    </td>
   </tr>
EOM

##
##
## Get the info for players that the owner is currently bidding on
##
##
########################
getBidding($total_spent,$league_t);

## End table for Bidding Targets
#
## Make column for Player Targets
print <<EOM;

</table>
</td>

<td valign=top style="Position: relative; left: 30; top: 30" class=none>
<table frame='box' cellpadding=5 bordercolor=#666666 border=3 style="table-layout: auto; width:300px;">
 <tr align=center>
  <td colspan=3>
   <b>Target Players</b>
  </td>
 </tr>
EOM

##
##
## Player Targets Stuff
##
##
###########################

$available_space = $max_players - $tic;
print <<FORM;
<form action="/cgi-bin/fantasy/getTarget.pl" method="post">
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

<form action="/cgi-bin/fantasy/addTarget.pl" method="post">

FORM

open(TARGETS,"<$targets");
flock(TARGETS,1);
 $my_count = -1;
 foreach $line (<TARGETS>)
 {
  chomp($line);
  ($owner,$target,$limit,$auto) = split(';',$line);
  if ($owner eq $team_t)
  {
    $my_count++;
    PrintTarget($target,$limit,$auto,$my_count);
  }
 }
close(TARGETS);

print <<EOFORM;

  <tr>
    <td colspan=3>
      <input type=hidden name=total value="$my_count">
      <center><input type=submit value="Update AutoBid"></center>
    </td>
  </tr>

EOFORM

## End File
Footer($user);

dbDisconnect($dbh);
