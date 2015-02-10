#!/usr/bin/perl
# script to check current bids on the fly
use Leagues;
use DBTools;
use JSON;
use CGI;
use Data::Dumper;
use POSIX qw(tzset);

my $cgi = new CGI;

## For special characters
binmode(STDOUT, ":utf8");

# Should modify to find the correct league here!
$user = $cgi->param('user');
$league_t = $cgi->param('league');
$player_ids = $cgi->param('ids');
$player_ids =~ s/;/,/g;
$player_ids =~ s/(\d+),/\'$1\',/g;

$players_won = "players_won";
$players_auction = "auction_players";
$players = "players";
$log = "/var/log/fantasy/checkBids.log";
$json_response;

open(LOG,">$log");
print LOG Dumper($cgi);

# DB-style
$dbh = dbConnect();

#Get League Data
$league = Leagues->new($league_t,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}

my $sport = $league->{_SPORT};
my $cap = $league->{_SALARY_CAP};
my $draftStatus = $league->{_DRAFT_STATUS};
my $draft_type = $league->draft_type();
my $prev_league = $league->prev_league();

## Time Stuff
$ENV{TZ} = 'America/New_York';
tzset;
($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime;
$current_seconds = time();
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

$Hour += $TZ_offset;
if($Hour >= 12)
{
 $time_string = "PM";
}
if ($Minute < 10)
{
  $Minute = '0' . "$Minute";
}
if ($Second < 10)
{
  $Second = '0' . "$Second";
}
$auction_string_hour = $Hour%12;
if ($auction_string_hour == 0)
{
  $auction_string_hour = 12;
}
$json_response->{TIME}->{MONTH} = $RealMonth;
$json_response->{TIME}->{DAY} = $Day;
$json_response->{TIME}->{HOUR} = $Hour;
$json_response->{TIME}->{MINUTE} = $Minute;
$json_response->{TIME}->{SECOND} = $Second;
$json_response->{TIME}->{CURRENT_SECONDS} = $current_seconds;
##$auction_string = "$RealMonth/$Day - $Hour:$Minute:$Second;$current_seconds";

## Prepare SQL statements to be used in loop(s) below
my $sth_rfa = $dbh->prepare("SELECT team from contracts where player=? and league='$prev_league'") or die "Cannot prepare: " . $dbh->errstr();

## Get list of auctioning players from dB
$sth = $dbh->prepare("SELECT a.name,a.price,a.team,a.time,a.rfa_override,p.name,p.position,p.team,t.price FROM $players_auction a, $players p LEFT JOIN (select playerid, price from targets where league='$league_t' and owner='$user') t ON p.playerid=t.playerid WHERE league = '$league_t' and p.playerid=a.name")
        or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
while (($id,$bid,$bidder,$ez_time,$rfa_override,$name,$pos,$team,$target) = $sth->fetchrow_array())
{
  if (! defined $json_response->{$id}) {
    $pos =~ s/\|/\//g;

    $target = 0 if (! defined $target);
 
    my $rfa_prev_owner = 'NA';


    ## Check for overridable draft statii
    if ($draftStatus eq 'paused') 
    {
      $ez_time = 'PAUSED';
    }
    elsif (($draft_type eq 'rfa') && ($ez_time <= $current_seconds))
    {
      if ($rfa_override ne 'WAIT') {
        next;
      }

      ## if this is RFA and the time is up, pass in a 'WAIT' placeholder while the previous owner decides
      $ez_time = 'WAIT';

      ## get the previous owner and pass that along - DO NOT use team name in case they differ league to league
      ## terrible field naming ... we actually use owner in the team field in contracts
      $sth_rfa->execute($id) or die "Cannot execute: " . $sth->errstr();
      $rfa_prev_owner = $sth_rfa->fetchrow();
    } elsif ($ez_time <= $current_seconds) {
      ## If time is expired and we're not in RFA 'WAIT' mode, don't return the player
      next;
    }

    $json_response->{PLAYERS}->{$id}->{NAME} = $name;
    $json_response->{PLAYERS}->{$id}->{POS} = $pos;
    $json_response->{PLAYERS}->{$id}->{TEAM} = $team;
    $json_response->{PLAYERS}->{$id}->{BID} = $bid;
    $json_response->{PLAYERS}->{$id}->{BIDDER} = $bidder;
    $json_response->{PLAYERS}->{$id}->{TIME} = $ez_time;
    $json_response->{PLAYERS}->{$id}->{TARGET} = $target;
    $json_response->{PLAYERS}->{$id}->{RFA_PREV_OWNER} = $rfa_prev_owner;
  }
}
$sth->finish();
$sth_rfa->finish();

## DO NOT REMOVE THIS LOOP BELOW UNLESS YOU HAVE A WORKING FIX!
### Get info on the players still on the auction page who have already been won
if ($player_ids !~ /^$/)
{
  $player_ids =~ s/,$//;
  $sth = $dbh->prepare("SELECT w.name,w.price,w.team,p.name,p.position,p.team FROM $players_won w, $players p WHERE w.league = '$league_t' and p.playerid in ($player_ids) and w.name=p.playerid");
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  while (($id,$bid,$bidder,$name,$pos,$team) = $sth->fetchrow_array())
  {
    $pos =~ s/\|/\//g;
    $json_response->{PLAYERS}->{$id}->{NAME} = $name;
    $json_response->{PLAYERS}->{$id}->{POS} = $pos;
    $json_response->{PLAYERS}->{$id}->{TEAM} = $team;
    $json_response->{PLAYERS}->{$id}->{BID} = $bid;
    $json_response->{PLAYERS}->{$id}->{BIDDER} = $bidder;
    $json_response->{PLAYERS}->{$id}->{TIME} = 'NA';
    $json_response->{PLAYERS}->{$id}->{TARGET} = 0;
    $json_response->{PLAYERS}->{$id}->{RFA_PREV_OWNER} = 'NA';
  }
  $sth->finish();

  ## Account for any expired players that were not claimed
  foreach my $player_id (split(/,/,$player_ids)) {
    $player_id =~ s/\'//g;
print LOG "Check expired for $player_id\n";
    if (($player_id =~ /^\d*$/) && (! defined $json_response->{PLAYERS}->{$player_id})) {
      $json_response->{PLAYERS}->{$player_id}->{BID} = 'NA';
      $json_response->{PLAYERS}->{$player_id}->{BIDDER} = 'NA';
      $json_response->{PLAYERS}->{$player_id}->{TIME} = 'NA';
    }
  }
}


# Find the max number of players that a team can have
if ($sport eq 'baseball')
{
  $max_players = 8; #default ## ECW 20090328 changed from 10 => 8 ; OF2 and OF3 are in the positions table
}
elsif ($sport eq 'football')
{
  $max_players = 6; #default                                                    
}
$max_players += scalar keys %{$league->{_POSITIONS}};

## Get all team rosters for getBids viewing
$sth_roster = $dbh->prepare("select p.name, w.team, w.price, p.position, w.rfa_override from players_won w, players p where w.name=p.playerid and w.league='$league_t' order by p.position,p.name");
$sth_roster->execute();
while (@team_roster = $sth_roster->fetchrow_array())
{
  my $roster_entry->{NAME} = $team_roster[0];
  $roster_entry->{POS} = $team_roster[3];
  $roster_entry->{PRICE} = $team_roster[2];
  push(@{$json_response->{ROSTERS}->{$team_roster[1]}},$roster_entry);

  ## while we're here ... if this is the RFA draft and this player was won in RFA, get his info
  if (($draft_type eq 'rfa') && ($team_roster[4] ne 'NA'))
  {
    $json_response->{RFA}->{$team_roster[0]}->{TEAM} = $team_roster[1];
    $json_response->{RFA}->{$team_roster[0]}->{PRICE} = $team_roster[2];
    $json_response->{RFA}->{$team_roster[0]}->{OVERRIDE} = $team_roster[4];
  }
}
$sth_roster->finish();


## Get roster and cash data for all other teams
$sth_teams = $dbh->prepare("select name,num_adds,money_plusminus,w.total,w.count from teams t LEFT JOIN (select team, sum(price) total,count(1) count from players_won where league='$league_t' group by team) w ON w.team=t.name where t.league='$league_t'");

my %seen_teams;
$sth_teams->execute();
while(my ($this_team, $team_adds, $team_plusminus, $won_cost, $won_num) = $sth_teams->fetchrow_array())
{
  ## If there are dual owners, we don't want to be sending back multiple team lines
  next if ($seen_teams{$this_team});
  $seen_teams{$this_team} = 1;

  if (!defined $won_cost)
  {
    $won_cost = 0;
  }

  $spots_left = $max_players - $won_num;
  $money_left = $cap - $won_cost + $team_plusminus; ## ECW 20080814 - added plusminus info from teams table, for altered cash
                                                    ##   (through trades (player4cash), canceled contracts, etc) 
  $max_bid = ($spots_left > 0) ? $money_left - (0.5 * ($spots_left - 1)) : 0;
  $json_response->{TEAMS}->{$this_team}->{MONEY} = $money_left;
  $json_response->{TEAMS}->{$this_team}->{MAX_BID} = $max_bid;
  $json_response->{TEAMS}->{$this_team}->{SPOTS} = $spots_left;
  $json_response->{TEAMS}->{$this_team}->{ADDS} = $team_adds;
}
$sth_teams->finish();

dbDisconnect($dbh);

my $json_text = to_json($json_response);
print "Content-type: application/json\n\n";
print $json_text;
