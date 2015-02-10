#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
my $cgi = new CGI;

####################
#
# Main Stuff
#
#  This file is to perform an action on a proposed trade
#  It can be accepted (and the players are swapped), it 
#  can be declined, or it can be canceled by the proposer.
#
####################

#variables that will be used later.
$return = "/cgi-bin/fantasy/teamHome.pl";
$team_error_file = "/var/log/fantasy/team_errors.txt";
$log = "/var/log/fantasy/log.txt";
$errorflag = 0;

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) = checkSession();

my $dbh = dbConnect();
   
$playerwonpage = "players_won";
$tradepage = "/var/log/fantasy/trades_$league_t.txt";
$trade_messages = "/var/log/fantasy/trade_messages_$league_t.txt";

#time stuff.
($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);

#24-hour scheme
$hour_tf = $Hour;
$daymins = (60 * $hour_tf) + $Minute;

my $RealMonth = $Month + 1;
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
   $Hour = $Hour % 12;
   $time_string = "PM";
}
if($Hour == 0)
{
   $Hour = 12;
}
if($Minute < 10)
{
   $Minute = "0" . $Minute; # add a leading zero to one-digit days
}


#Get League Data
$sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($league_name,$league_password,$league_owner,$league_draftType,$league_draftStatus,$league_contractStatus,$league_sport,$league_categories,$league_positions,$league_max_members,$league_start_money,$auction_length,$bid_time_extension, $bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
$sth->finish();

# Crudely find out how many people are allowed per roster
if ($sport_t eq 'baseball')
{
  $max_players = 10; #default

  @test_positions = ("Util ","Util2","Util3","Util_IN","Util_OF","SP2","SP3","RP2","RP3","P1","P2","P3","B1","B2","B3","B4","B5");
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

  open (FILE,"<$trade_messages");
  flock(FILE,1);
  @LINES=<FILE>;
  chop (@LINES);
  close(FILE);
  $SIZE=@LINES; 

  ## clear any unwanted trade alert messages
  open(FILE,">$trade_messages");
  flock(FILE,2);
  for ($x=0;$x<$SIZE;$x++)
  {
 $line = $LINES[$x];
 ($owner,$message) = split(';',$line);
 $temp = "msg_decision$x";
 $check = $cgi->param("$temp");
 if ($check ne "cancel")
 {
   print FILE "$line\n";
 }
  }
  close(FILE);
 
  open (FILE,"<$tradepage");
  flock(FILE,1);
  @LINES=<FILE>;
  chop (@LINES);
  close(FILE);
  $SIZE=@LINES; 
  
  open (FILE,">$tradepage");
  flock(FILE,2);
  for ($x=0;$x<$SIZE;$x++)
  {
   $error_flag = 0;
   $line = @LINES[$x];
   ($receiver,$proposer,$numgets,$costgets,$idstoget,$numgives,$costgives,$idstogive) = split(';',$line);
   $temp = "decision$x";
   $check = $cgi->param("$temp");


   if ($check eq "yes")
   { 
      #find number of players won/bidding by both owners
      $money_spent_rec  = 0;
      $money_spent_prop = 0;
      $players_won_rec  = 0;
      $players_won_prop = 0;

      $sth = $dbh->prepare("SELECT SUM(price), COUNT(price) FROM $playerwonpage WHERE team=? AND league='$league_t'");
      $sth->execute($receiver) or die "Cannot execute: " . $sth->errstr();
       ($money_spent_rec,$players_won_rec) = $sth->fetchrow_array();
      $sth->finish();  ## ECW - is this needed here?
      $sth->execute($proposer) or die "Cannot execute: " . $sth->errstr();
       ($money_spent_prop,$players_won_prop) = $sth->fetchrow_array();
      $sth->finish();


      $money_bidding_rec  = 0;
      $money_bidding_prop = 0;
      $players_bidding_rec  = 0;
      $players_bidding_prop = 0;
          
      $sth = $dbh->prepare("SELECT SUM(price), COUNT(price) FROM auction_players WHERE team=? AND league='$league_t'");
      $sth->execute($receiver) or die "Cannot execute: " . $sth->errstr();
      ($money_bidding_rec,$players_bidding_rec) = $sth->fetchrow_array();
      $sth->finish();  ## ECW - is this needed here?
      $sth->execute($proposer) or die "Cannot execute: " . $sth->errstr();
      ($money_bidding_prop,$players_bidding_prop) = $sth->fetchrow_array();
      $sth->finish();


      ## Find plus/minus moneys for the teams
      $sth_plusminus = $dbh->prepare("select money_plusminus from teams where team=? and league='$league_t'");
      $sth_plusminus->execute($receiver);
       $money_plusminus_rec = $sth_plusminus->fetchrow();
      $sth_plusminus->finish();
      $sth_plusminus->execute($proposer);
       $money_plusminus_prop = $sth_plusminus->fetchrow();
      $sth_plusminus->finish();

     $proposer_names = '';
     $receiver_names = '';
     $sth_get_name = $dbh->prepare("SELECT name from players where playerid=?");
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

     

     # Make sure that the bidder's roster has space to make this bid
     if ($players_won_prop + $players_bidding_prop + ($numgets - $numgives) > $max_players)
     {
       open(MESS,">>$trade_messages");
       flock(MESS,2);
       print MESS "$receiver;<b>Trading $proposer_names for $receiver_names would overflow the roster for $proposer!<b>\n";
       print MESS "$proposer;<b>Trading $receiver_names for $proposer_names would overflow the roster for $proposer!<b>\n";
       close(MESS);
       $error_flag = 1;
     }
     elsif($players_won_rec + $players_bidding_rec + ($numgives - $numgets) > $max_players)
     {
       open(MESS,">>$trade_messages");
       flock(MESS,2);
       print MESS "$receiver;<b>Trading $proposer_names for $receiver_names would overflow the roster for $receiver!<b>\n";
       print MESS "$proposer;<b>Trading $receiver_names for $proposer_names would overflow the roster for $receiver!<b>\n";
       close(MESS);
       $error_flag = 1;
     }

     ########################
     ## Money logic here
     ########################
     elsif (($money_bidding_rec + $money_spent_rec + $costgives - $costgets) > ($league_start_money + $money_plusminus_rec))
     {
       open(MESS,">>$trade_messages");
       flock(MESS,2);
       print MESS "$receiver;<b>Trading $proposer_names for $receiver_names would put $receiver over the salary cap!<b>\n";
       print MESS "$proposer;<b>Trading $proposer_names for $receiver_names would put $receiver over the salary cap!<b>\n";
       close(MESS);
       $error_flag = 1;
     }
     elsif (($money_bidding_prop + $money_spent_prop + $costgets - $costgives) > ($league_start_money + $money_plusminus_prop))
     {
       open(MESS,">>$trade_messages");
       flock(MESS,2);
       print MESS "$receiver;<b>Trading $proposer_names for $receiver_names would put $proposer over the salary cap!<b>\n";
       print MESS "$proposer;<b>Trading $proposer_names for $receiver_names would put $proposer over the salary cap!<b>\n";
       close(MESS);
       $error_flag = 1;
      } 


    if ($error_flag != 1)
    {
       ## Switch players from each team
##two '@players_' arrays below likely be killed ...
       @ids_got = split(':',$idstoget);
       @ids_given = split(':',$idstogive);

       foreach(@ids_got)
       {
         $sth = $dbh->prepare("UPDATE $playerwonpage set team='$proposer' WHERE name = '$_' AND league = '$league_t'");
         $sth->execute();
         $sth->finish();
       }

       foreach(@ids_given)
       {
         $sth = $dbh->prepare("UPDATE $playerwonpage set team='$receiver' WHERE name = '$_' AND league = '$league_t'");
         $sth->execute();
         $sth->finish();
       }

       ## print to each others boards, print to main board
       open(TRADES,">>$trade_messages");
       flock(TRADES,2);
       print TRADES "$proposer;You have traded $receiver_names to $receiver for $proposer_names!\n";
       print TRADES "$receiver;You have traded $proposer_names to $proposer for $receiver_names!\n";
  
       $sth_teams = $dbh->prepare("SELECT name from teams where league='$league_t' and name not in ('$receiver','$proposer')");
       $sth_teams->execute();
       while(my $msg_team = $sth_teams->fetchrow())
       {
         print TRADES "$msg_team;$proposer has traded $receiver_names to $receiver for $proposer_names\n";
       }
       $sth_teams->finish();
       close(TRADES);
    } 
  } #end if(check eq yes)

    
 elsif ($check eq "no")
 {

   ## Print to proposer's message board that trade was turned down
   open(TRADES,">>$trade_messages");
   flock(TRADES,2);
   print TRADES "$proposer;Your trade to $receiver was turned down\n";
   close(TRADES);
 }

 elsif ($check ne "cancel")
 {
   # if no action is taken, just leave the trade alone
   print FILE "$line\n";
 }
  }
  close(FILE);
  # set return?

dbDisconnect($dbh);
print "Location: $return\n\n";
