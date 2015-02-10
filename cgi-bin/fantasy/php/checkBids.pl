#!/usr/bin/perl
# script to check current bids on the fly
use DBI;

($string1, $string2) = split('=',$ENV{'QUERY_STRING'});
$string2 =~ s/%20/ /g;

# Should modify to find the correct league here!
($league_t, $player_data) = split(',',$string2);
@players = split(';',$player_data);
$players_won_file = "players_won";
$players_auction_file = "auction_players";
$log = "./checkBids_log.txt";
$return_string = "";

# DB-style
$dbh = DBI->connect("DBI:mysql:doncote_draft:localhost","doncote_draft","draft")
            or die "Couldn't connect to database: " .  DBI->errstr;

#Get League Data
$sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_start_time,$auction_end_time,$auction_length,$bid_time_extension, $bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
$sth->finish();


## Time Stuff
($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
my $RealMonth = $Month + 1;
if($RealMonth < 10)
{
   $RealMonth = "0" . $RealMonth; 
}
if($Day < 10)
{
   $Day = "0" . "$Day"; # add a leading zero to one-digit days
}
$Fixed_Year = $Year + 1900;
$time_string = "AM";
if($Hour >= 12)
{
 $time_string = "PM";
}
if ($Minute < 10)
{
  $Minute = '0' . "$Minute";
}


$auction_string_hour = $Hour%12;
if ($auction_string_hour == 0)
{
  $auction_string_hour = 12;
}
$auction_string = "$RealMonth/$Day - $auction_string_hour:$Minute $time_string";

## Prepare SQL statements to be used in loop below
$sth_owner_name = $dbh->prepare("SELECT * FROM teams WHERE name = ? and league='$league_t'")
                   or die "Cannot prepare: " . $dbh->errstr();
$sth_email = $dbh->prepare("SELECT passwd FROM passwd WHERE name=? ")
                   or die "Cannot prepare: " . $dbh->errstr();
$sth_replace = $dbh->prepare("REPLACE INTO $players_won_file VALUES(?,?,?,?,?,?,'$league_t')")
                   or die "Cannot prepare: " . $dbh->errstr();
$sth_remove = $dbh->prepare("DELETE FROM $players_auction_file WHERE name=? AND league = '$league_t'")
                   or die "Cannot prepare: " . $dbh->errstr();
$sth_update = $dbh->prepare("Update teams set num_adds=? where name=? and league='$league_t'")
                   or die "Cannot prepare: " . $dbh->errstr();


## Trying to add players-won logic here . . .
$sth_while = $dbh->prepare("SELECT * FROM $players_auction_file WHERE league = '$league_t'")
        or die "Cannot prepare: " . $dbh->errstr();
$sth_while->execute() or die "Cannot execute: " . $sth_while->errstr();

while (($name,$pos,$bid,$bidder,$time,$ez_time,$league) = $sth_while->fetchrow_array())
{
      $time_over = 0;
      ($end_month,$end_day,$end_hour,$end_minute) = split(':',$ez_time);

      # If the player goes unclaimed, flag it
      $player_claimed = 1;
      if ($bidder eq '<b>UNCLAIMED</b>')
      {
	  $player_claimed = 0;
      }

      ## CRAZY auction-done logic - improve to account for day change?
      if (($RealMonth > $end_month)
           ||
         (
          ($RealMonth == $end_month) 
            && 
          (
           ($Day > $end_day)
            || 
           (
            ($Day == $end_day)
              && 
            (
             ($Hour > $end_hour)
              || 
             (
              ($Hour == $end_hour)
               &&
              ($Minute >= $end_minute)
             )
            )
           )
          )
         )
        )
      {

	 $time_over = 1;

         # in case our server is in a different time zone . . .
         $right_hour = $Hour + $TZ_offset;
         if($right_hour >= 0) 
         {
           $right_hour = $right_hour%12;
         }

         ## If the time is over - no matter whether or not player was won, just DELETE him
         $sth_remove->execute($name) or die "Cannot execute: " . $sth_remove->errstr();

         if ($player_claimed == 1)
         {
             ## Get owner name for winning team
             $sth_owner_name->execute($bidder) or die "Cannot execute: " . $sth_owner_name->errstr();
             ($tf_owner, $tf_name, $tf_league, $tf_adds, $tf_sport) = $sth_owner_name->fetchrow_array();


             # If an owner is not found, send the email to the commish
             if ($tf_name =~ /^$/)
             {
                 # default to commissioners email
        	 $tf_owner = 'COMMISSIONER';
                 $owner_email = "akeely\@coe.neu.edu";
             }
             else
             {
                 ##Get owner email info!!
                 $sth_email->execute($tf_owner) or die "Cannot execute: " . $sth_email->errstr();
                 ($owner_email) = $sth_email->fetchrow_array();
              }


              ########################
              #                      #
              # SEND EMAIL TO WINNER #
              #                      #
              ########################
        
              #my $mailprog = '/usr/sbin/sendmail';
              #my $recipient = "$owner_email";

              #open(MSG, ">>$messagefile");
              #flock(MSG,2);
              #print MSG "<b>AUCTION ALERT</b>;$RealMonth/$Day/$Fixed_Year ($right_hour:$Minute $time_string EST);<b>The bidding for $name has been won by $bidder for a price of $bid.</b>\n";
              #close(MSG);


              #open (MAIL, "|$mailprog -t");
              #print MAIL "To: $recipient\n";
              #print MAIL "Subject: $bidder has won the auction on $name!\n\n";

              # print message here, with same syntax, eg.
              #print MAIL "Congratulations! You have won the fantasy baseball auction on $name, for the final bid of $bid. This player has been added to your team roster, so please visit the roster screen to view the changes and see how much money you have remaining.\n\nAlso, you may now add a new player to the auction, or defer the decision to the commissioner. Please go to http://www.zwermp.com/cgi-bin/fantasy/getPlayer.pl and select a player who has not yet been auctioned. This only allows for ONE new player addition with an initial \$0.50 bid, so be sure that you think about which player you want to add at this time.\n\nAgain, if you do not want to add a player yourself, simply check the box to give the commissioner permission to add a new player, and he will take care of it. Be warned that once you give permission to the commissioner, this one addition will be revoked.\n\nCongratulations on acquiring $name, and good luck with the season!";

              #close(MAIL);

              # DB-style     
              # update players won file
              $sth_replace->execute($name,$pos,$bid,$bidder,$time,$ez_time);

              ## Update num_adds for winner
              $tf_adds = $tf_adds+1;
              $sth_update->execute($tf_adds,$bidder) or die "Cannot execute: " . $sth_update->errstr();

         } #end if (player_claimed)

         else
         {
              open(MSG, ">>$messagefile");
               flock(MSG,1);
               print MSG "<b>AUCTION ALERT</b>;$RealMonth/$Day/$Fixed_Year ($right_hour:$Minute $time_string EST);<b>$name was not claimed in the auction</b>\n";
              close(MSG);
         }

     } #end if (time_over)

     ########################
     # Else if the time is not over, do nothing - leave players in the database
     ########################

} #end for-loop
$sth_while->finish();
$sth_owner_name->finish();
$sth_email->finish();
$sth_replace->finish();
$sth_remove->finish();
$sth_update->finish();


## Get new list of players from dB
# DB-style
$sth = $dbh->prepare("SELECT * FROM $players_auction_file WHERE name = ? AND league = '$league_t'")
        or die "Cannot prepare: " . $dbh->errstr();
$sth2 = $dbh->prepare("SELECT position,price,team FROM $players_won_file WHERE name = ? AND league = '$league_t'")
        or die "Cannot prepare: " . $dbh->errstr();
foreach (@players)
{
  $sth->execute($_) or die "Cannot execute: " . $sth->errstr();
  ($name,$pos,$bid,$bidder,$time,$ez_time,$league) = $sth->fetchrow_array();


  if ($name eq $_)
  {
    $time = $ez_time - time();
    $return_string = "$name,$pos,$bid,$bidder,$time;$return_string";
  }
  # bid expired
  else
  {
    $sth2->execute($_) or die "Cannot execute: " . $sth2->errstr();
    ($pos,$bid,$bidder) = $sth2->fetchrow_array();
    $return_string = "$_,$pos,$bid,$bidder,NA;$return_string";
  }
}
$sth->finish();
$sth2->finish();

# append any players recently added
$sth = $dbh->prepare("SELECT * FROM $players_auction_file WHERE league = '$league_t'")
        or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();

while (($name,$pos,$bid,$bidder,$time,$ez_time,$league) = $sth->fetchrow_array())
{
  if ($return_string !~ /$name,$pos,$bid/)
  {
    $time = $ez_time - time();
    $return_string = "$name,$pos,$bid,$bidder,$time;$return_string";
  }
}
$sth->finish();

## Remove trailing ';' for $return_string
chop($return_string);


@test_positions = ();
# Find the max number of players that a team can have
if ($sport eq 'baseball')
{
  $max_players = 10; #default                                                   
  @test_positions = ("Util","Util2","Util3","Util4","Util_IN","Util_OF","SP2","SP3","SP4","RP2","RP3","RP4","P1","P2","P3","P4","B1","B2","B3","B4","B5","B6","B7","B8","B9");
}
elsif ($sport eq 'football')
{
  $max_players = 6; #default                                                    
  @test_positions = ("QB2","QB3","QB4","RB2","RB3","RB4","WR2","WR3","WR4","TE2","TE3","TE4","OFF1","OFF2","K2","K3","K4","DEF2","DEF3","DEF4","B1","B2","B3","B4","B5","B6","B7","B8","B9");
}

foreach (@test_positions)
{
  if ($positions =~ /$_/)
  {
      $max_players++;
  }
}


## Get roster and cash data for all other teams
$sth = $dbh->prepare("select sum(price), count(*) from $players_won_file where team=? and league='$league_t'");
$sth2 = $dbh->prepare("select sum(price), count(*) from $players_auction_file where team=? and league='$league_t'");
$sth_teams = $dbh->prepare("select name from teams where league='$league_t'");

$stats_string = "";
$sth_teams->execute();
while(($this_team) = $sth_teams->fetchrow_array())
{
  $sth->execute($this_team);
  ($won_cost, $won_num) = $sth->fetchrow_array();

  # Not "used" now
  $sth2->execute($this_team);
  ($bidding_cost, $bidding_num) = $sth->fetchrow_array();

  if (!defined $won_cost)
  {
    $won_cost = 0;
  }

  $spots_left = $max_players - $won_num;
  $money_left = $cap - $won_cost;
  $stats_string .= "$this_team,$money_left,$spots_left;";
}

## Remove trailing ';' for $stats_string
chop($stats_string);

$dbh->disconnect();
print "Content-type: text/html\n\n";
print "$return_string|$auction_string|$stats_string";