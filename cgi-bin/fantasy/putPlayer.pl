#!/usr/bin/perl

use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Leagues;
use Session;
use DBTools;
use Data::Dumper;

my $cgi = new CGI;
use POSIX qw(ceil floor);

## For special characters
binmode(STDOUT, ":utf8");

open(LOG,">/var/log/fantasy/putPlayer.log");
print LOG Dumper($cgi);

#variables that will be used later.
$return = "/cgi-bin/fantasy/getPlayerIndex.pl";
$error_file = "/var/log/fantasy/add_errors.txt";
$team_error_file = "/var/log/fantasy/team_errors.txt";

### Input Variables
$in_player_id = $cgi->param('player_id');
$in_commish_flag = $cgi->param('commish_flag');

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();
my $dbh = dbConnect();

## If the user is valid, return will be a status string
print "Content-type: text/html\n\n";

$playerwonpage = "players_won";
$message_page = "/var/log/fantasy/message_board_$league_t.txt";
$targets = "/var/log/fantasy/player_targets_$league_t.txt";
$auction_table = "auction_players";

#Get League Data
$league = Leagues->new($league_t,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}

my $sport = $league->{_SPORT};
my $cap = $league->{_SALARY_CAP};
my $draftStatus = $league->{_DRAFT_STATUS};
my $auction_length = $league->{_AUCTION_LENGTH};
my $draftType = $league->{_DRAFT_TYPE};
my $prev_league = $league->prev_league();

## Confirm that Auction is open (Allow additions while paused)
if ($draftStatus eq 'closed')
{
  print "0;The draft for league $league_t is closed!";
  exit;
}


########################################
#                                      #
#            DO TIME STUFF             #
#                                      #
########################################
## length is in minutes (possibly decimals, i.e. 2.5 = 2 mins 30 seconds)
$endsecs = time() + ($auction_length * 60);


########################################
#                                      #
# CHECK ADDITION VALIDITY              #
#                                      #
########################################

print LOG "SELECT name FROM players WHERE playerid='$in_player_id'\n";
$sth_get_name = $dbh->prepare("SELECT name FROM players WHERE playerid='$in_player_id'")
                 or die "Cannot prepare: " . $dbh->errstr();
$sth_get_name->execute();
my $name = $sth_get_name->fetchrow();
$sth_get_name ->finish(); 

# Check to make sure user can add a player
$sth = $dbh->prepare("SELECT * FROM teams WHERE league = '$league_t' AND name = '$team_t'")
     or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();

($tf_owner, $tf_name, $tf_league, $tf_adds, $tf_sport, $tf_plusminus) = $sth->fetchrow_array();
$sth->finish();

if (($tf_adds < 1) && ($in_commish_flag ne 'true'))
{
  print "0;You cannot add any more players right now!";
  exit;
}

## Prevent adds during RFA. Only commish can add (until we automate this?)
if ($draftType eq 'rfa')
{
  if ($in_commish_flag ne 'true')
  {
    print "0;You cannot manually add players during the RFA draft!";
    exit;
  }

  ## If commish is adding, confirm that this player is up for the RFA draft
  $sth = $dbh->prepare("SELECT count(1) from contracts where league='$prev_league' and player='$in_player_id' and years_left='-1' and broken='N'");
  $sth->execute();
  my $rfa_check = $sth->fetchrow();
  $sth->finish();
  if ($rfa_check != 1)
  {
    print "0;$name is not eligible for the RFA draft!";
    exit;
  }
}

#find number of players won by this owner  
$sth = $dbh->prepare("SELECT COUNT(*) FROM $playerwonpage WHERE team = '$team_t' AND league = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
$players_won = $sth->fetchrow_array();
$sth->finish();

#find number of players currently being led in bidding by this owner  
$sth = $dbh->prepare("SELECT COUNT(*) FROM $auction_table WHERE team = '$team_t' AND league = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
$players_bidding = $sth->fetchrow_array();
$sth->finish();

# Find the max number of players that a team can have
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
$sth_check_pos->finish();

if ((($players_bidding + $players_won) >= $max_players) & ($in_commish_flag ne 'true'))
{
  print "0;This player would be added with an initial bid of 0.50. However, if you win this player your roster will be overfilled.\nIf you still wish to add this player, please contact the commissioner.";
  exit;
}

########################################
#                                      #
# TEST FOR MISSING ESSENTIAL ENTRIES!! #
#                                      #
########################################
# If any essential entries are missing (player names, positions), return error
if ($in_player_id =~ /^$/)
{
  print "0;You must select a player!";
  exit;
}

#Confirm that player can be auctioned
$sth_player = $dbh->prepare("select count(*) from players where playerid='$in_player_id' and (exists (select 'x' from players_won where name=playerid and league='$league_t') or exists (select 'x' from auction_players where name=playerid and league='$league_t'))");
$sth_player->execute();
if ($sth_player->fetchrow() > 0)
{
  print "0;Your player has already been added to the auction!";
  exit;
}
$sth_player->finish();

########################################
#                                      #
# ADD PLAYER WHEN ALL ENTRIES ARE GOOD #
#                                      #
########################################
  
  my $rfa_override_status = ($draftType eq 'rfa') ? 'WAIT' : 'NA';

  # Avoid assigning initial value to commissioner's actual team
  if ($in_commish_flag eq 'true')
  {
     $sth = $dbh->prepare("INSERT INTO $auction_table VALUES ('$in_player_id','0.00','<b>UNCLAIMED</b>','$endsecs','$league_t','$rfa_override_status')");
     $sth->execute() or die "\n\n***Sorry Commish! $name has already been added to the auction!***\n\nPlease go back and select a new player\n\n";     
     $sth->finish();
  }

  ## Else this is not a commish entry, so assign an initial bid to the adding team
  else
  {
     ## RFA override status should always be 'NA' here, since only commish can add to RFA auction
     $sth = $dbh->prepare("INSERT INTO $auction_table VALUES ('$in_player_id','0.50','$team_t','$endsecs','$league_t','$rfa_override_status')");
     $sth->execute() or die "\n\n***Sorry! $name has already been added to the auction!***\n\nPlease go back and select a new player\n\n" . $sth->errstr();   
     $sth->finish();

     # If the adding party is not the commissioner, we must decrement this team's available addition total
     $tf_adds = $tf_adds - 1;
     $sth = $dbh->prepare("UPDATE teams SET num_adds = '$tf_adds' WHERE league = '$league_t' and name='$team_t'")
          or die "Cannot prepare: " . $dbh->errstr();
     $sth->execute() or die "Cannot execute: " . $sth->errstr();
     $sth->finish();
  }

  print "1;$name has been added!";

dbDisconnect($dbh);
