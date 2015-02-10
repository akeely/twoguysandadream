#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use DBTools;
use Session;
$cgi = new CGI;


#$roster_file = $cgi->param('file');
$roster_file = './final_roster_loads/2008PeoplesAuction_finalRoster.csv';
$table = 'final_rosters';

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();
my $dbh = dbConnect();

$sth_clear = $dbh->prepare("update $table set team='NONE' where league='$league_t'");
##$sth_select_id = $dbh->prepare("select playerid from players where name=? and sport='$sport_t' and upper(team)=upper(?)");
$sth_select_id = $dbh->prepare("select playerid from players where name=? and sport='$sport_t' and (team=? OR team='FA')");
$sth_select_id_def = $dbh->prepare("select playerid from players where name=? and sport='$sport_t'");
$sth_select = $dbh->prepare("SELECT * FROM $table WHERE name=? and league='$league_t'");
$sth_replace = $dbh->prepare("update $table set team=? where name=? and league='$league_t'");
$sth_insert = $dbh->prepare("insert into $table (name,price,team,league) values (?,0,?,'$league_t')");

## Assign all players from this draft to 'NONE' owner. Real (current) owner will be assigned below
$sth_clear->execute();
$sth_clear->finish();
print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";

open (ROSTER,"<$roster_file");
flock(1,ROSTER);
foreach $roster (<ROSTER>)
{
  chomp($roster);
  ($q_team, $junk) = split(/\t/, $roster,2);
  $junk =~ s/\"//g;
  $junk =~ s/\'//g;
  $junk =~ s/^\s+//;
  $junk =~ s/\s+$//;
  my $id;
  my @junk_fields = split(/ /, $junk);
  if (@junk_fields == 2)
  {
    ## This is a defense
    $q_name = $junk_fields[0];
    $q_pos = 'DEF';
    $sth_select_id_def->execute($q_name);
    $id = $sth_select_id_def->fetchrow();
  }
  else
  {
    ## Not a defense - will have at least 3 fields (last name, first name POS TEAM)
    $q_pro_team = $junk_fields[@junk_fields - 1];
    $q_pos = $junk_fields[@junk_fields - 2];
    my $comma_index = index($junk,", ",0);
    my $name_end_index = index($junk," $q_pos ",0);
    $q_name = substr($junk,($comma_index + 2),($name_end_index - $comma_index - 1)) . ' ' . substr($junk,0,$comma_index);
    $q_name =~ s/  / /; ## odd double-spacing issue
    $sth_select_id->execute($q_name, $q_pro_team);
    $id = $sth_select_id->fetchrow();
  }

  if (defined $id)
  {
    $sth_select->execute($id);

    if (@player_row = $sth_select->fetchrow_array())
    {
      ## If there is row for the player in the DB, update to the correct owner data
      ($name, $price, $team, $timestring, $time, $league) = @player_row;
##print "UPDATE for $q_name, $q_team ($id) - $team => $q_team<br>"
      $sth_replace->execute($q_team, $name);
    }
    else
    {
      ## Else, add new row for this player - he was undrafted at start of season
##print "INSERT for $q_name, $q_team ($id) - $q_team<br>"
      $sth_insert->execute($id,$q_team);
    }
  }
  else
  {
    print "'$q_name', '$q_pro_team' ($roster) is not found in the 'players' table!<br>";
  }
}

close(ROSTER);
$sth_select->finish();
$sth_replace->finish();
$sth_insert->finish();
dbDisconnect($dbh);
