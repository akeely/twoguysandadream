#!/usr/bin/perl
# script to update the RFA flag in auction_players after an override decision has been made
use DBTools;
use Leagues;

($string1, $string2) = split('=',$ENV{'QUERY_STRING'});
$string2 =~ s/%20/ /g;

## FYI - 'prev_owner' here is actually the user, not the team
($player,$league_name,$prev_owner,$override) = split(';',$string2);

open(LOG,">/var/log/fantasy/updateRfaPlayer.log");
print LOG "player: $player, league_name: $league_name, prev_owner: $prev_owner, override: $override\n";

$dbh = dbConnect();

#Get League Data
$league = Leagues->new($league_name,$dbh);
if (! defined $league)
{
  print LOG "LEAGUE NOT FOUND\n";
  die "ERROR - league object not found!\n";
}
$prev_league = $league->prev_league();

## Make assumptions, override below if necessary
my $rfa_override = 'NO';

print LOG "SELECT team from auction_players where name=$player and league='$league_name'\n";
$sth_get_current_owner = $dbh->prepare("SELECT team from auction_players where name=$player and league='$league_name'");
$sth_get_current_owner->execute();
my $owner = $sth_get_current_owner->fetchrow();
$sth_get_current_owner->finish();

# TODO - error handling if this record is not found?
print LOG "current owner check: $owner\n";

## Check if the previous owner wants to override
if ($override eq 'true')
{
  ## If we have an override request, confirm that this is truly the previous owner
  $sth = $dbh->prepare("SELECT t.owner, t.name from teams t, contracts c where c.player=$player and c.team=t.owner and t.league='$prev_league' and c.league=t.league") or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  ($prev_owner_check, $prev_team) = $sth->fetchrow_array();
  $sth->finish();

  print LOG "prev_owner_check: $prev_owner_check\n";
  if ($prev_owner_check eq $prev_owner)
  {
    ## Use the team here for auction_players
    $owner = $prev_team;
    $rfa_override = 'YES';
  }
}

print LOG "UPDATE auction_players set team='$owner', rfa_override='$rfa_override' where name='$player' and league='$league_name'\n";
$sth = $dbh->prepare("UPDATE auction_players set team='$owner', rfa_override='$rfa_override' where name='$player' and league='$league_name'");
$sth->execute() or die "Cannot execute: " . $sth->errstr();
$sth->finish();
dbDisconnect($dbh);

close(LOG);

print "Content-type: text/html\n\n";
print "OKOKOK";
