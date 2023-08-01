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
$log = "./putContracts_log.txt";

open (FILE,">$error_file"); 
       flock(FILE,2);
       print FILE " ";
      close(FILE);


## Input variables
$team = $cgi->param('TEAMS');
$in_total_players = $cgi->param('total_players');
$in_lock_status = $cgi->param('LOCK_ME');

open (LOG,">./$log");

# find out the name of the session user
## Connect to sessions database

my ($ip,$sess_id,$sport_t,$leagueid, $teamid, $ownerid, $ownername, $teamname) = checkSession();
$dbh = dbConnect();

#Get League Data
$league = Leagues->new($leagueid,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}

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
          $sth = $dbh->prepare("REPLACE INTO $contract_table (playerid,ownerid,total_years,years_left,current_cost,leagueid,locked) VALUES ('$id',$ownerid,'$years','$years_left','$cost',$leagueid,'yes')");
       }
       else
       {
          $sth = $dbh->prepare("REPLACE INTO $contract_table (playerid,ownerid,total_years,years_left,current_cost,leagueid) VALUES ($id,$ownerid,'$years','$years_left','$cost',$leagueid)");
       }
      
       $sth->execute() or die "Cannot execute: " . $sth->errstr();
       $sth->finish();
     }
     else
     {
       $sth = $dbh->prepare("DELETE FROM $contract_table WHERE playerid = $id AND leagueid = $leagueid and locked = 'no'");
       $sth->execute() or die "Cannot execute: " . $sth->errstr();
       $sth->finish();
     }
  }

close(LOG);
dbDisconnect($dbh);
print "Location: $return\n\n";
