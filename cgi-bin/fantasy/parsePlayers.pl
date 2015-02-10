#!/usr/bin/perl
use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use Session;
use DBTools;
use Leagues;
use URI;
use JSON;
use Data::Dumper;
my $cgi = new CGI;

# find out the name of the session user
## Connect to sessions database

my ($my_ip,$namer,$pswd,$my_id,$team_t,$sport_t,$league_t) = checkSession();
my $dbh = dbConnect();

#Get League Data
$league = Leagues->new($league_t,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}
my $draft_type = $league->draft_type();
my $prev_league = $league->prev_league();

$temp_players = "/var/log/fantasy/temp_" . $sport_t . "_players.txt";

my $uri = URI->new($ENV{'HTTP_REFERER'});
my $path = $uri->path;
if (($path eq "/cgi-bin/fantasy/listPlayers.pl") || ($path eq "/cgi-bin/fantasy/getTarget.pl"))
{
  $return = "$ENV{'HTTP_REFERER'}";
}
elsif ($path eq "/cgi-bin/fantasy/getPlayer.pl")
{
  $return = "/cgi-bin/fantasy/getPlayerIndex.pl";
}
else
{
  $return = "/cgi-bin/fantasy/getTeam.pl";
}

open(LOG,">/var/log/fantasy/parsePlayers_log.out") or die("$!");
print LOG Dumper($cgi);

$in_position = $cgi->param('position');
$in_name = $cgi->param('name');
$in_ranked = $cgi->param('ranked');
$in_timeframe = $cgi->param('timeframe');
$in_rfa = $cgi->param('rfa');
$in_team = $cgi->param('team');
$in_league = $cgi->param('league');

$rosters = "players_won";
$auction = "auction_players";

## if timeframe is 'final', use the final rosters table instead
## TODO how does this work if not finalized yet? Just won't show teams?
if ($in_timeframe eq 'final')
{
  $rosters = 'final_rosters';
}

print LOG "$in_timeframe, $rosters\n";

#Get Team Info
$sth = $dbh->prepare("SELECT * FROM teams WHERE league = '$in_league' AND name = '$in_team'");
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($tf_owner, $tf_name, $tf_league, $tf_adds, $tf_sport, $tf_plusminus) = $sth->fetchrow_array();
$sth->finish();


$WHERE = "active=1 and sport='$sport_t'";
$SORT  = "order by SUBSTRING_INDEX(name,' ',-1) asc";

if ($sport_t eq 'baseball')
{
  $WHERE .= " and (position not like '%P%')" if ($in_position eq 'Util');
  $WHERE .= " and (position like '%P%')" if ($in_position eq 'P');
  $WHERE .= " and (position like '%$in_position%')" if (($in_position ne 'Util') and ($in_position ne 'P') and ($in_position ne 'ALL'));
}
elsif ($sport_t eq 'football')
{
  $WHERE .= " and (position like '%$in_position%')" if ($in_position ne 'ALL');
}

## If the user requests name funneling, apply that to the query
$WHERE .= " and (name like '% $in_name%')" if ($in_name ne "ALL");

## If the user requests a ranked search, sort appropriately
$SORT = "order by rank" if ($in_ranked eq 'on');

## If the user requests RFA results only ...
my $FROM = 'players p';
if ($in_rfa eq 'on')
{
  $FROM .= ', contracts c';
  $WHERE .= " and c.league='$prev_league' and c.player=p.playerid and c.years_left <= 0 and c.broken = 'N'";
  $SORT = "order by rand()";
}

print LOG "$FROM $WHERE $SORT\n";

## Get Players currently in auction
my %auction_players;
my $sth_check_auction = $dbh->prepare("SELECT name FROM $auction WHERE league = '$league_t'");
$sth_check_auction->execute();
while (my $auction_playerid = $sth_check_auction->fetchrow()) {
  $auction_players{$auction_playerid} = 1;
}
$sth_check_auction->finish();

## Get players won / final rosters for this league
my %players_won;
my $sth_check_rosters = $dbh->prepare("SELECT name, team, price FROM $rosters WHERE league = '$league_t'");
$sth_check_rosters->execute();
while (my ($won_playerid, $won_owner, $won_cost) = $sth_check_rosters->fetchrow_array()) {
  $players_won{$won_playerid}->{'OWNER'} = $won_owner;
  $players_won{$won_playerid}->{'COST'} = $won_cost;
}
$sth_check_rosters->finish();


my $json_response;
$json_response->{'ADDS'} = $tf_adds;
my $sth_check_contracts = $dbh->prepare("SELECT team, broken, years_left FROM contracts WHERE player = ? AND league = '$league_t' and locked='yes'");
$sth_players = $dbh->prepare("select p.playerid,p.name,p.position,p.team,p.rank from $FROM where $WHERE $SORT");
$sth_players->execute();
while (my ($id,$player,$pos,$team,$rank) = $sth_players->fetchrow_array())
{
  $found = 0;
  $player =~ s/'/ /g;

  # Check auction for player name
  if (defined $auction_players{$id})
  {
    $found = 1;
# TODO ugh we're returning markup
    $owner = "<b>IN AUCTION</b>";
  }
  

  # check players won / final rosters / contracts for player name
  if ($found == 0)
  {
    if (defined $players_won{$id})
    {
      $found = 1;
# TODO ugh we're returning markup
      $owner = "<b>" . $players_won{$id}->{'OWNER'} . "</b>";
      $cost = "<b>" . $players_won{$id}->{'COST'} . "</b>";

      ## If we're looking for final rosters, see if this dude is on an expiring contract. If so, list him as such
      if ($in_timeframe eq 'final')
      {
        $sth_check_contracts->execute($id) or die "Cannot execute: " . $sth_check_contracts->errstr();
        my ($c_owner, $broken, $years_left) = $sth_check_contracts->fetchrow_array();

        if (($broken eq 'Y') || ($years_left == -1)) 
        {
          $owner = 'NONE (EXP)';
          $cost = "<b>*$cost*</b>";
        }
        elsif (defined $c_owner)
        {
          $owner = "<b>$c_owner</b>";
          $cost = "<b>*$cost*</b>";
        }
      }
    }
  }

  if ($found == 0)
  {
    $owner = "NONE";
    $cost = "---";
  }

  my $player_object->{'ID'} = $id;
  $player_object->{'CAN_ADD'} = ($owner =~ /^NONE/) ? 1 : 0;
  $player_object->{'NAME'} = $player;
  $player_object->{'POSITION'} = $pos;
  $player_object->{'TEAM'} = $team;
  $player_object->{'RANK'} = $rank;
  $player_object->{'OWNER'} = $owner;
  $player_object->{'COST'} = $cost;

  push(@{$json_response->{'PLAYERS'}}, $player_object);
}
$sth_players->finish();
$sth_check_contracts->finish();

dbDisconnect($dbh);
my $json_text = to_json($json_response);

print "Content-type: application/json\n\n";
print $json_text;


sub by_names
{
  ($a_player,$a_pos,$a_team) = split(';',$players_array{$a});
  ($b_player,$b_pos,$b_team) = split(';',$players_array{$b});
  @a_names = split(' ', $a_player);
  @b_names = split(' ', $b_player);

  $a_size = @a_names;
  $b_size = @b_names;

  ($a_names[$a_size - 1] cmp $b_names[$b_size - 1]) || ($a_names[0] cmp $b_names[0]);
}
