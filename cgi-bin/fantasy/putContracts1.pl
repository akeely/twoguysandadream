#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Leagues;
use Session;
use DBTools;

$cgi = new CGI;

#variables that will be used later.
$return = "/cgi-bin/fantasy/getContracts.pl"; 
$error_file = "/var/log/fantasy/contract_errors.txt";
$errorflag=0;
$log = "./putContracts_log.txt";

open (FILE,">$error_file"); 
       flock(FILE,2);
       print FILE " ";
      close(FILE);


## Input variables
$team = $cgi->param('TEAMS');
$in_TEAM_PASSWORD = $cgi->Param('TEAM_PASSWORD');
$in_total_players = $cgi->param('total_players');
$in_lock_status = $cgi->param('LOCK_ME');

open (LOG,">./$log");

# find out the name of the session user
## Connect to sessions database

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();
$dbh = dbConnect();

#Get League Data
$league = Leagues->new($league_t,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}

## If we are not tracking the user by Session, check the input password
if (! $league->{_SESSIONS_FLAG})
{
  ## Connect to password database

  my $table = "passwd";
  $owner = '';
  $sth = $dbh->prepare("SELECT * FROM $table WHERE name = '$team' AND passwd = '$in_TEAM_PASSWORD'")
          or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  ($owner,$password,$email) = $sth->fetchrow_array();
  $sth->finish();

  if($owner ne $in_TEAMS)
  {
    $errorflag=1;
    $return = "/cgi-bin/fantasy/getBids.pl";
    open (FILE,">>$error_file"); 
     flock(FILE,2);
     print FILE "$team_t;$league_t;<b>Your Password is Incorrect!</b>\n";
    close(FILE);
  }
}


if ($errorflag == 0)
{
  $contract_table = "contracts";

print LOG "Total players - $in_total_players\n\n";
  for($x=0; $x < $in_total_players; $x++)
  {
    ## get the players to be acquired
     $id = $cgi->param("idout$x");
     $cost = $cgi->param("costout$x");
     $years = $cgi->param("Year$x");
     $years_left = $years;
print LOG "id - $id\ncost - $cost\nyears - $years\n\n";

     if (($id !~ /^$/) && ($years !~ /^$/))
     {
       if ($in_lock_status eq 'true')
       {
          $sth = $dbh->prepare("REPLACE INTO $contract_table (player,team,total_years,years_left,current_cost,league,locked) VALUES ('$id','$team','$years','$years_left','$cost','$league_t','yes')");
       }
       else
       {
          $sth = $dbh->prepare("REPLACE INTO $contract_table (player,team,total_years,years_left,current_cost,league) VALUES ('$id','$team','$years','$years_left','$cost','$league_t')");
       }
      
       $sth->execute() or die "Cannot execute: " . $sth->errstr();
       $sth->finish();
     }
     else
     {
       $sth = $dbh->prepare("DELETE FROM $contract_table WHERE player = '$id' AND league = '$league_t' and locked = 'no'");
       $sth->execute() or die "Cannot execute: " . $sth->errstr();
       $sth->finish();
     }
  }

}

close(LOG);
dbDisconnect($dbh);
print "Location: $return\n\n";
