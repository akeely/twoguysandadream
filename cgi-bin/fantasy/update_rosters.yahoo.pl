#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use Session;
use DBTools;
use CGI::Cookie;
$cgi = new CGI;

print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";

my $upload_dir = "./final_roster_loads";
my $file = $cgi->param('roster_file');

$table = 'final_rosters';
$trial_run = 0; ## Set this to 0 to apply changes to DB - best to use 1 for first try, check STDOUT for errors

## Translation for Yahoo team defenses to ESPN/TGaaD storage
my %team_lut = (
                 'Arizona' => 'Cardinals',,
                 'Atlanta' => 'Falcons',,
                 'Baltimore' => 'Ravens',
                 'Buffalo' => 'Bills',
                 'Carolina' => 'Panthers',
                 'Chicago' => 'Bears',
                 'Cincinnati' => 'Bengals',
                 'Cleveland' => 'Browns',
                 'Dallas' => 'Cowboys',
                 'Denver' => 'Broncos',
                 'Detroit' => 'Lions',
                 'Green Bay' => 'Packers',
                 'Houston' => 'Texans',
                 'Indianapolis' => 'Colts',
                 'Jacksonville' => 'Jaguars',
                 'Kansas City' => 'Chiefs',
                 'Miami' => 'Dolphins',
                 'Minnesota' => 'Vikings',
                 'New England' => 'Patriots',
                 'New Orleans' => 'Saints',
                 'New York Giants' => 'Giants',
                 'New York Jets' => 'Jets',
                 'Oakland' => 'Raiders',
                 'Philadelphia' => 'Eagles',
                 'Pittsburgh' => 'Steelers',
                 'San Diego' => 'Chargers',
                 'San Francisco' => '49ers',
                 'Seattle' => 'Seahawks',
                 'St. Louis' => 'Rams',
                 'Tampa Bay' => 'Buccaneers',
                 'Tennessee' => 'Titans',
                 'Washington' => 'Redskins'
                );


my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();

my $dbh = dbConnect();
$sth_select_id = $dbh->prepare("select playerid from players where name=? and sport='$sport_t'");

my $line_count = 0;
my $error = 0;
my $id = '';
my %players;
my %teams;

print "OPENING '$file'<br><br>";
##open (ROSTER,"<$file");
##flock(1,ROSTER);
##foreach $roster (<ROSTER>)
foreach $roster (<$file>)
{
  $line_count++;
  chomp($roster);
##  ($q_team, $junk) = split(/\t/, $roster);
##  ($q_name, $junk) = split(/ \(/, $junk);
##  ($junk, $q_pos) = split(/ - /,$junk);
##  $q_pos =~ s/\)//;
##  chop($q_pos); # Remove trailing ')'

  ($q_team, $q_name) = split(/\t/, $roster);

  if (! defined $q_team)
  {
    print "TEAM is undefined on line $line_count!<br>";
    $error = 1;
  }
  if (! defined $q_name)
  {
    print "PLAYERNAME is undefined on line $line_count!<br>";
    $error = 1;
  }

  ## Replace bad characters ... sorry Latin America
  $q_name =~ s/\'//g;
  $q_name =~ s/&#193;/A/g;
  $q_name =~ s/&#201;/E/g;
  $q_name =~ s/&#243;/o/g;
  $q_name =~ s/&#233;/e/g;
  $q_name =~ s/&#237;/i/g;
  $q_name =~ s/&#225;/a/g;
  $q_name =~ s/&#250;/u/g;
  $q_name =~ s/&#241;/n/g;
  $q_name =~ s/Á/A/g;
  $q_name =~ s/é/e/g;
  $q_name =~ s/ó/o/g;
  $q_name =~ s/ú/u/g;
  $q_name =~ s/ñ/n/g;
  $q_name =~ s/á/a/g;
  $q_name =~ s/í/i/g;

  if ($error != 1)
  {

    $q_name =~ s/^\s+//;
    $q_name =~ s/\s+$//;

    ## Use our internal team names if this is a DEFense
    $q_name = $team_lut{$q_name} if (defined $team_lut{$q_name});

    $sth_select_id->execute($q_name);
     my $ids = $sth_select_id->fetchall_arrayref();
    $sth_select_id->finish();

    if (@{$ids} == 0)
    {
      print "'$q_name' ($roster) is not found in the 'players' table! Contact Andrew/Erik for updating this table<br>";
      $error = 1;
    }
    elsif (@{$ids} > 1)
    {
      print "'$q_name' {$roster} has " .@{$ids}. " matches in the DB. Please check and manually add!<br>";
##      $error = 1;
    }
    else
    {
      $id = @{$ids}[0]->[0];
      print "'$q_name' => $id<br>";
    }
  }

  ## If we hit any errors, die - make user fix them
  if ($error == 1)
  {
    print "Line $line_count: $roster<br>";
    print "PLEASE FIX YOUR FILE ERRORS!<br><br>";
    print "File format: 'fantasyteamname&lt;TAB&gt;playername (Team - POS)'<br>";
    print "Example:     'Rhode Island Reds&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Brandon Lyon (Det - RP)'<br>";
    close(ROSTER);
    dbDisconnect($dbh);
    exit(15);
  }

 
  ## If we make it here, build a hash with the roster elements  
  $players{$id} = "$q_team;$q_name";

  ## Keep track of all team names seen - we need to check that these are legit teams!
  $teams{$q_team} = 1;
}


## Check those team names!
$sth_check_team = $dbh->prepare("select count(1) from teams where name=? and league='$league_t'");
foreach my $team (keys %teams)
{
  $sth_check_team->execute($team);
  if ($sth_check_team->fetchrow < 1)
  {
    print "Team '$team' is not found for league '$league_t' - Perhaps you need to map Yahoo->Auction names?<br>";
    $error = 1;
  }
}
exit(16) if ($error ==1);

## No more errors! Just load/print our stuff
print "<b>$line_count players ready to be loaded!</b><br><br>";

$sth_clear = $dbh->prepare("update $table set team='NONE' where league='$league_t'");
$sth_select = $dbh->prepare("SELECT * FROM $table WHERE name=? and league='$league_t'");
$sth_replace = $dbh->prepare("update $table set team=? where name=? and league='$league_t'");
$sth_insert = $dbh->prepare("insert into $table (name,price,team,league) values (?,0,?,'$league_t')");

## Assign all players from this draft to 'NONE' owner. Real (current) owner will be assigned below
$sth_clear->execute();
$sth_clear->finish();

my $insert_count = 0;
my $update_count = 0;
foreach my $id (keys %players)
{
  my ($q_team,$q_name) = split(/;/,$players{$id});
  $sth_select->execute($id);

  if (@player_row = $sth_select->fetchrow_array())
  {
    ## If there is row for the player in the DB, update to the correct owner data
    ($name, $price, $team, $timestring, $time, $league) = @player_row;
    print "update $table for $q_team, $name ($q_name)<br>" if ($trial_run == 1);
    $sth_replace->execute($q_team, $name) if ($trial_run == 0);
    $update_count++;
  }
  else
  {
    ## Else, add new row for this player - who was undrafted at start of season
    $sth_insert->execute($id,$q_team) if ($trial_run == 0);
    print "insert $table for $q_team, $id ($q_name)<br>" if ($trial_run == 1);
    $insert_count++;
  }
}

close(ROSTER);
$sth_select->finish();
$sth_replace->finish();
$sth_insert->finish();
dbDisconnect($dbh);

print "$insert_count players were inserted in '$table'<br>";
print "$update_count players were updated in '$table'<br><br><br>";

print "Check out these players in the <a href='/cgi-bin/fantasy/getContracts.pl'><font color='blue'>Contracts</font></a> page!<br>";