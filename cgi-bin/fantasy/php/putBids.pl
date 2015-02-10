#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
my $cgi = new CGI;

####################
#
# Main Stuff
#
####################

#variables that will be used later.
$return = 'http://www.zwermp.com/cgi-bin/fantasy/php/getBids.php';
$error_file = './error_logs/bid_errors.txt';
$team_error_file = './error_logs/team_errors.txt';
$log = './putBids_log.txt';
$target_base = './text_files/player_targets';

$errorflag = 0;

## Input variables
$in_TEAMS = $cgi->param('TEAMS');
$in_TEAM_PASSWORD = $cgi->param('TEAM_PASSWORD');
$in_total_players = $cgi->param('total_players');


open (FILE,">$error_file");
      flock(FILE,2);
      print FILE "\n";
      close(FILE);


#time stuff.
$current_time = time();


# find out the name of the session user
my $query = new CGI;
my $cookie = "SESS_ID";
my $id = $query->cookie(-name => "$cookie");
my $ip = "";
my $userAddr = $ENV{REMOTE_ADDR};
$dbh = DBI->connect("DBI:mysql:doncote_draft:localhost","doncote_draft","draft")
              or die "Couldn't connect to database: " .  DBI->errstr;

# If the cookie is valid, get the IP that the session is for
if($id){
  $sth = $dbh->prepare("SELECT * FROM sessions WHERE sess_id = '$id'")
        or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
      ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = $sth->fetchrow_array();
  $sth->finish();
}

# If the session is from a different IP, force the user to sign in
if ($ip ne $userAddr)
{
  open(TEAM,">$team_error_file");
  flock(TEAM,2);
  print TEAM "<b>You must login!</b>\n";
  close(TEAM);

  $dbh->disconnect();
  print "Location: http://www.zwermp.com/cgi-bin/fantasy/getTeam.pl\n\n";
  exit;
}

else
{

    #Get League Data
    $sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
             or die "Cannot prepare: " . $dbh->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    ($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$league_positions,$max_members,$cap,$auction_start_time,$auction_end_time,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
    $sth->finish();

    $playerpage = "auction_players";
    $playerwonpage = "players_won";
    $target_base .= "_$league_t.txt";

    #####################################
    ###  If bidder must enter password, check it
    #####################################
    if ($use_IP_flag eq 'no')
    {
      ## Make sure that the owner has selected a team name
      if ($in_TEAMS eq "Select Your Team")
      {
        open (FILE,">>$error_file");
        flock(FILE,2);
        print FILE "$team_t;$league_t;<b>Please Select a Team Name!</b>\n";
        close(FILE);
        $errorflag = 1;
        $return = "http://www.zwermp.com/cgi-bin/fantasy/getBids.pl";
      }

      ## CHECK PASSWORD ##
      if ($errorflag != 1)
      {
        if ($in_TEAM_PASSWORD =~ /^$/)
        {
           open (FILE, ">>$error_file");
           flock(FILE,2);
           print FILE "$team_t;$league_t;<b>The password field must be filled out to properly submit this form!</b>\n";
           close(FILE);
           $errorflag = 1;
           $return = "http://www.zwermp.com/cgi-bin/fantasy/getBids.pl";
        }
        else
        {
           
           
          ## Connect to password database
          my $table = "passwd";
          $owner = '';
          $sth = $dbh->prepare("SELECT * FROM $table WHERE name = '$in_TEAMS' AND passwd = '$in_TEAM_PASSWORD'")
                  or die "Cannot prepare: " . $dbh->errstr();
          $sth->execute() or die "Cannot execute: " . $sth->errstr();
          ($owner,$password,$email) = $sth->fetchrow_array();
          $sth->finish();

          if($owner ne $in_TEAMS)
          {
            $errorflag=1;
            $return = "http://www.zwermp.com/cgi-bin/fantasy/getBids.pl";
            open (FILE,">>$error_file"); 
             flock(FILE,2);
             print FILE "$team_t;$league_t;<b>Your Password is Incorrect!</b>\n";
            close(FILE);
          }
          else
          {
            # get team name for this owner bid
            $sth = $dbh->prepare("SELECT name FROM teams WHERE owner = '$user' AND league = '$league_t'")
                     or die "Cannot prepare: " . $dbh->errstr();
            $sth->execute() or die "Cannot execute: " . $sth->errstr();
            $team_t = $sth->fetchrow_array();
            $sth->finish();
          }

        }
      }

    } # end if ($use_IP_flag eq 'no')

    if ($errorflag != 1)
    {
      # Find out how many people are allowed per roster
      if ($sport_t eq 'baseball')
      {
        $max_players = 10; #default

        @test_positions = ("Util ","Util2","Util3","Util_IN","Util_OF","SP2","SP3","RP2","RP3","P1","P2","P3","B1","B2","B3","B4","B5","B6");
      }
      elsif ($sport_t eq 'football')
      {
        $max_players = 6; #default

        @test_positions = ("QB2","QB3","RB2","RB3","WR2","WR3","TE2","OFF1","OFF2","K2","DEF2","B1","B2","B3","B4","B5","B6");
      }

      foreach (@test_positions)
      {
        if ($league_positions =~ /$_/)
        {
          $max_players++;
        }
      }


      # Find which auction-board players have been bid on
      @in_players = ();
      @in_bids    = ();
      for ($p=1; $p<=$in_total_players;$p++)
      {
        $temp1 = "PLAYER_NAME_$p";
        $temp_player = $cgi->param("$temp1");
        $temp2 = "NEW_BID_$p";
        $temp_bid = $cgi->param("$temp2");

        $sth = $dbh->prepare("SELECT * FROM $playerpage where name = '$temp_player' AND league = '$league_t'")
             or die "Cannot prepare: " . $dbh->errstr();
        $sth->execute() or die "Cannot execute: " . $sth->errstr();

        ($a1,$a2,$a3,$a4,$a5,$a6,$a7) = $sth->fetchrow_array();

        if (($a1 ne '') & ($temp_bid > 0))
        {
          push(@in_players,$temp_player);
          push(@in_bids, $temp_bid);
        }
        $sth->finish();
      }
   
      ## Check to make sure user has made at least one bid
      $bid_made = 0;
      for ($x=1;$x<=$in_total_players;$x++)
      {
          $temp = "NEW_BID_$x";
          $new_bid = $cgi->param("$temp");
          if ($new_bid > 0)
          {
            $bid_made = 1;
            last;
          }
      }

      if ($bid_made == 0)
      {
        open(FILE,">$error_file");
         flock(FILE,1);
         print FILE "$team_t;$league_t;<b>You must make at least one new bid!</b>\n";
        close(FILE);
        $errorflag = 1;
      }
   }
}

if ($errorflag != 1)
{
 
  open(FILE,">$error_file");
  flock(FILE,2);
  print FILE "\n";
  close(FILE);
 
  #####################################
  ### TOTALS ALREADY WON IN AUCTION ###
  #####################################
  #find money spent by this owner
  $sth = $dbh->prepare("SELECT SUM(price) FROM $playerwonpage WHERE team = '$team_t' AND league = '$league_t'")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  $money_spent = $sth->fetchrow_array();
  $sth->finish();

  #find number of players won by this owner  
  $sth = $dbh->prepare("SELECT COUNT(*) FROM $playerwonpage WHERE team = '$team_t' AND league = '$league_t'")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  $players_won = $sth->fetchrow_array();
  $sth->finish();

  ###########################################
  ### TOTALS CURRENTLY WINNING IN AUCTION ###
  ###########################################
  #find money currently in bidding by this owner
  $sth = $dbh->prepare("SELECT SUM(price) FROM $playerpage WHERE team = '$team_t' AND league = '$league_t'")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  $money_bidding = $sth->fetchrow_array();
  $sth->finish();

  #find number of players currently being led in bidding by this owner  
  $sth = $dbh->prepare("SELECT COUNT(*) FROM $playerpage WHERE team = '$team_t' AND league = '$league_t'")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  $players_bidding = $sth->fetchrow_array();
  $sth->finish();


  # Get owners bids (may be multiple)
  $loop_run = @in_players;
  for ($x=0;$x < $loop_run;$x++)
  {
      $added = 0;
      $can_bid = 1;
      $new_bid = $in_bids[$x];
      $input_player_name = $in_players[$x];
      
      # Get db info about this player
      $sth = $dbh->prepare("SELECT * FROM $playerpage where name='$input_player_name' AND league = '$league_t'")
           or die "Cannot prepare: " . $dbh->errstr();
      $sth->execute() or die "Cannot execute: " . $sth->errstr();
      ($old_name,$old_pos,$old_bid,$old_bidder,$old_time_string,$old_time,$league) = $sth->fetchrow_array();
      $sth->finish();


      ##################################################
      #### Determine if owner can make a bid      ######
      ##################################################
      
      if ($old_bidder eq $team_t)
      {
        $test_bid = $new_bid - $old_bid;
        $test_players_bidding = $players_bidding;
      }
      else
      {
        $test_bid = $new_bid;
        $test_players_bidding = $players_bidding + 1;
      }
      
      # Make sure that the bidder's roster has space to make this bid
      if (((($players_won + $players_bidding >= $max_players) && ($old_bidder ne $team_t)) || ((($players_won+$players_bidding-1) >= $max_players) && ($old_bidder eq $team_t))) && ($new_bid > 0))
      {
        open(FILE,">$error_file");
        flock(FILE,2);
        print FILE "$team_t;$league_t;<center><b>Bidding on $input_player_name will overfill your roster! $players_won, $players_bidding <?> $max_players<b></center>\n";
        close(FILE);
      }

##################################
#                                #
#  CHECK MONEY REMAINING/BIDDING #
#                                #
##################################
      # Make sure that the bidder has enough money to make this bid (money unavailable = money spent + money current in other bids + (minimum bid * empty roster spots)
      elsif ($cap < ($test_bid + $money_bidding + $money_spent + ($max_players - $test_players_bidding - $players_won)*(0.5)))
      {
          open(FILE,">$error_file");
          flock(FILE,2);
          print FILE "$team_t;$league_t;<center><b>You cannot afford to bid $new_bid on $input_player_name!</b></center>\n";
          close(FILE);
      }
###################################
#                                 #
#  MAKE SURE BID IS HIGH ENOUGH 1 #
#                                 #
###################################
      elsif ($old_bid > 10)
      {
        if ($new_bid >= ($old_bid + 1))
        {
          $added = 1;
        }
        elsif ($new_bid != 0)
        {
          open(FILE,">$error_file");
          flock(FILE,2);
          print FILE "$team_t;$league_t;<center><b>Your bid for $input_player_name must bid at least 1 dollar higher than the previous bid!</b></center>\n";
          close(FILE);
        }
      } #end elsif
###################################
#                                 #
#  MAKE SURE BID IS HIGH ENOUGH 2 #
#                                 #
###################################
      elsif($new_bid >= ($old_bid + 0.5))
      {
        $added = 1;
      }
      elsif ($new_bid != 0)
      {
        open(FILE,">$error_file");
        flock(FILE,2);
        print FILE "$team_t;$league_t;<center><b>Your bid for $input_player_name must bid at least 0.5 dollars higher than the previous bid!</b></center>\n";
        close(FILE);
      }

#######################################
#                                     #
#  RESET AUCTION END TIME, IF NEEDED  #
#                                     #
#######################################

     if ($added == 1)
      {




        # If a bid is made during "down time" - set the end time to the start
        if (($current_time < $auction_start_time) || ($current_time >= $auction_end_time))
        {
          # start the next day, plus buffer
          $end_time = $auction_start_time + 24*60*60 + $bid_time_buffer*60;

        }

        
        # If the bid is made during auction time, extend the auction by the
        #  extension time if needed
        elsif((($current_time - $old_time) < ($bid_time_buffer*60)))
        {
	  $end_time = $current_time + $bid_time_buffer*60;          
            
        }


        $sth = $dbh->prepare("REPLACE INTO $playerpage VALUES ('$input_player_name','$old_pos','$new_bid','$team_t','$old_time_string','$end_time','$league_t')")
               or die "Cannot prepare: " . $dbh->errstr();
        $sth->execute() or die "Cannot execute: " . $sth->errstr();

        $sth->finish();
      }

############################################
#                                          #
#  ADD THE PLAYER BACK TO THE AUCTION FILE #
#                                          #
############################################
      
      if ($added == 1)
      {
        # if for any reason the owner outbids his/her own previous high bid, only increase the tally (money_bidding) by the difference between the bids, and don't increment the number of players being bid upon!
        if ($old_bidder eq $team_t)
        {
          $money_bidding += ($new_bid - $old_bid);
        }     
        # if the owner outbids a different owner, update the owners money_bidding tally, and increment the number of players he/she is bidding upon.
        else
        {
          $money_bidding += $new_bid;
          $players_bidding++;
        }
        
      } #end if(added == 1)
  } # end for-loop
} #end if (errorflag != 1)

$dbh->disconnect();
print "Location: $return\n\n";