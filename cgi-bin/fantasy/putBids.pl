#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use JSON;
use Leagues;
use Session;
use DBTools;
use Data::Dumper;

my $cgi = new CGI;

####################
#
# Main Stuff
#
####################

#variables that will be used later.
$return = '/cgi-bin/fantasy/getBids.pl';
$log = '/var/log/fantasy/putBids_log.txt';
$target_base = '/var/log/fantasy/player_targets';

## Input variables
$in_TEAMS = $cgi->param('TEAMS');
$in_TEAM_PASSWORD = $cgi->param('TEAM_PASSWORD');
$in_total_players = $cgi->param('total_players');

open(LOG, ">$log");
print LOG Dumper($cgi);
print LOG $cgi->param("PLAYER_ID_0") . "\n";


#time stuff.
$current_seconds = time();


my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();
my $dbh = dbConnect();

#Get League Data
$league = Leagues->new($league_t,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}

$sport = $league->{_SPORT};
$cap = $league->{_SALARY_CAP};
$bid_time_buffer = $league->{_BID_TIME_BUFF};
$bid_time_extension = $league->{_BID_TIME_EXT};
$draft_type = $league->{_DRAFT_TYPE};
$prev_league = $league->prev_league();

$playerpage = "auction_players";
$playerwonpage = "players_won";
$target_base .= "_$league_t.txt";

# get team name and cash info for this owner bid
$sth = $dbh->prepare("SELECT name, money_plusminus FROM teams WHERE owner = '$user' AND league = '$league_t'")
  or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
 ($team_t, $plusminus_t) = $sth->fetchrow_array();
$sth->finish();
        
        
# Find out how many people are allowed per roster
if ($sport_t eq 'baseball')
{
  $max_players = 8; #default
}
elsif ($sport_t eq 'football')
{
  $max_players = 6; #default
}

my $sth_check_pos = $dbh->prepare("select count(1) from positions where league='$league_t'");
$sth_check_pos->execute();
$max_players += $sth_check_pos->fetchrow();


# Find which auction-board players have been bid on
## Also,  check to make sure user has made at least one bid
@in_players = ();
@in_bids    = ();
$sth = $dbh->prepare("SELECT count(1) FROM $playerpage where name = ? AND league = '$league_t'");
for ($p=0; $p<$in_total_players;$p++)
{
  $temp1 = "PLAYER_ID_$p";
  $temp_player = $cgi->param("$temp1");
  $temp2 = "NEW_BID_$p";
  $temp_bid = $cgi->param("$temp2");

  $sth->execute($temp_player) or die "Cannot execute: " . $sth->errstr();
  if (($sth->fetchrow() > 0) & ($temp_bid > 0))
  {
    push(@in_players,$temp_player);
    push(@in_bids, $temp_bid);
  }
}
$sth->finish();
   
my $json_response;
if ($#in_bids >= 0)
{
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
  my $sth_player_info = $dbh->prepare("SELECT w.price,w.team,w.time,w.rfa_override,p.position,p.name FROM auction_players w, players p where w.name=? AND w.league = '$league_t' and w.name=p.playerid");
  my $sth_prev_owner = $dbh->prepare("SELECT t.name from teams t, contracts c where c.player=? and c.team=t.owner and t.league='$prev_league' and c.league=t.league") or die "Cannot prepare: " . $dbh->errstr();
  my $sth_reset_auction = $dbh->prepare("REPLACE INTO $playerpage (name,price,team,time,league,rfa_override) VALUES (?,?,?,?,?,?)");
  for ($x=0;$x < $loop_run;$x++)
  {
      $added = 0;
      $can_bid = 1;
      $new_bid = $in_bids[$x];
      $new_bid =~ s/^0+//;  ## Remove leading zeros ... Don
      my ($bid_dollar,$bid_cent) = split(/\./,$new_bid);
      $input_player_id = $in_players[$x];
      
      # Get db info about this player
      $sth_player_info->execute($input_player_id) or die "Cannot execute: " . $sth_player_info->errstr();
      ($old_bid,$old_bidder,$old_ez_time,$rfa_override,$old_pos,$player_name) = $sth_player_info->fetchrow_array();


      # if this is the rfa draft, determine the previous owner
      $sth_prev_owner->execute($input_player_id) or die "Cannot execute: " . $sth_prev_owner->errstr();
      $rfa_prev_owner = $sth_prev_owner->fetchrow();

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
        $json_response->{'player_errors'}->{$input_player_id} = "Bidding on $player_name will overfill your roster!"; 
      }

##################################################
#                                                #
#  RFA BIDDING LOGIC - CAN'T BID ON YOUR OWN GUY #
#                                                #
##################################################
      elsif (($draft_type eq 'rfa') && ($team_t eq $rfa_prev_owner))
      {
        $json_response->{'player_errors'}->{$input_player_id} = "You cannot actively bid on your own player ($player_name) during the RFA draft! You will have the chance to override the highest bid before he is sold"; 
      }

##################################
#                                #
#  CHECK MONEY REMAINING/BIDDING #
#                                #
##################################
      # Make sure that the bidder has enough money to make this bid (money unavailable = money spent + money current in other bids + (minimum bid * empty roster spots)
      ## 20080818 - add team's cash +/- to the cap, to raise/lower their total available cash flow
      elsif (($cap + $plusminus_t) < ($test_bid + $money_bidding + $money_spent + ($max_players - $test_players_bidding - $players_won)*(0.5)))
      {
          $json_response->{'player_errors'}->{$input_player_id} = "You cannot afford to bid $new_bid on $player_name!";
      }
###################################
#                                 #
#  MAKE SURE BID IS HIGH ENOUGH 1 #
#                                 #
###################################
      elsif ($old_bid >= 10)
      {
        ## First, it must be at least 1 dollar higher
        if ($new_bid >= ($old_bid + 1))
        {
          ## Second, it must be a dollar value (no 'cents' - thats for bids less-than $10)
          if ((defined $bid_cent) && ($bid_cent !~ /^0*$/))
          {
            $json_response->{'player_errors'}->{$input_player_id} = "Bids over \$10 must be made in dollar increments! ($player_name $new_bid)";
          }
          else { $added = 1; }
        }
        elsif ($new_bid != 0)
        {
          $json_response->{'player_errors'}->{$input_player_id} = "Your bid for $player_name must be at least 1 dollar higher than the previous bid!";
        }
      } #end elsif
###################################
#                                 #
#  MAKE SURE BID IS HIGH ENOUGH 2 #
#                                 #
###################################
      elsif($new_bid >= ($old_bid + 0.5))
      {
        if ((defined $bid_cent) && ($bid_cent !~ /^50?$/) && ($bid_cent !~ /^0{1,2}$/))
        {
          $json_response->{'player_errors'}->{$input_player_id} = "Bids under \$10 must be made in increments of at least 50 cents";
        }
        else { $added = 1; }
      }
      elsif ($new_bid != 0)
      {
        $json_response->{'player_errors'}->{$input_player_id} = "Your bid for $player_name must be at least 0.5 dollars higher than the previous bid";
      }
######################################
#                                    #
#  CHECK FOR AUTO BIDS               #
#                                    #
######################################

# KNOWN BUGS
#   checks for auto-bids even on bad bids
#   only increments by 0.5 even if over $10

#      # count number of teams with auto-bids
#      my $count = 2;
     
#      # allow auto-bids to bid up each other
#      while($count > 1){
#         $count = 0;

#         open(TARGETS,"<$target_base");
#         flock(TARGETS,1);

#         # check each target for auto-bids
#         foreach(<TARGETS>){

#             ($t_team, $t_name, $t_bid, $t_auto) = split(/;/);
         
#             if($t_name eq $name && 
#                $t_auto =~ /yes/ &&
#                $t_bid >= $old_bid+0.5 &&
#                $ ne $old_bidder){
         
#                 $bid[$x] = $bid[$x]+0.5;
#                 $bidder[$x] = $t_team;
#                 $count = $count + 1;
#                 if($bid[$x] > 10){
#                     $bid[$x] += 0.5;
#                 }
#             }
#          }

#          close(TARGETS);

#       }
            
#######################################
#                                     #
#  RESET AUCTION END TIME, IF NEEDED  #
#                                     #
#  UPDATE PLAYER AUCTION RECORD IN DB #
#                                     #
#######################################

     if ($added == 1)
      {
        # Extend the auction by the extension time, if needed
        if (($current_seconds + (60 * $bid_time_buffer)) > $old_ez_time)
        {
          ## ECW 3/25/2008 - now add bid_time_extension to current time (not previous end time)
          $old_ez_time = $current_seconds + ($bid_time_extension * 60);
        }

        $sth_reset_auction->execute($input_player_id,$new_bid,$team_t,$old_ez_time,$league_t,$rfa_override) or die "Cannot execute: " . $sth_reset_auction->errstr();
        $json_response->{'player_success'}->{$input_player_id} = 1;
      }

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
  $sth_player_info->finish();
  $sth_prev_owner->finish();
  $sth_reset_auction->finish();
} else {
  $json_response->{'no_change'} = 1;
}

$dbh->commit();
dbDisconnect($dbh);

my $json_text = to_json($json_response);
print LOG Dumper($json_text);

print "Content-type: application/json\n\n";
print $json_text;
