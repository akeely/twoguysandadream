#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use Leagues;
use CGI;
use CGI::Cookie;
use Session;
use DBTools;

$cgi = new CGI;

#variables that will be used later.
$return = "/cgi-bin/fantasy/getTags.pl"; 
$error_file = "/var/log/fantasy/tag_errors.txt";
$log = "./putTags_log.txt";

open (FILE,">$error_file"); 
       flock(FILE,2);
       print FILE " ";
      close(FILE);


## Input variables
$team = $cgi->param('TEAMS');
$in_league = $cgi->param('league');
$in_lock_status = $cgi->param('LOCK_ME');
$in_tag_type = $cgi->param('tag_type');
$in_player_name = $cgi->param('player_name');
$in_player_cost = $cgi->param('player_cost');
$in_player_pos = $cgi->param('player_pos');
$in_player_id = $cgi->param("$in_player_name" . "_id");

my ($ip,$sess_id,$sport_t,$leagueid, $teamid, $ownerid, $ownername, $teamname) = checkSession();
my $dbh = dbConnect();

#Get League Data
$league = Leagues->new($leagueid,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}


open(LOG,">$log");
print LOG "in_league - $in_league\n";
print LOG "in_lock_status - $in_lock_status\n";
print LOG "in_tag_type - $in_tag_type\n";
print LOG "in_player_name - $in_player_name\n";
print LOG "in_player_cost - $in_player_cost\n";
print LOG "in_player_pos - $in_player_pos\n";
print LOG "in_player_id - $in_player_id\n";

  ## If owner selects 'NONE' - make sure their tag is clear (unless it was already locked)
  if ($in_player_name eq 'NONE')
  {
    $sth = $dbh->prepare("DELETE FROM tags WHERE ownerid = $ownerid and leagueid = $leagueid and locked='no'");
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    $sth->finish();
  }
  else
  {
    my %existing_frans;
    my $can_franchise = 1;
    $sth = $dbh->prepare("SELECT playerid, locked, active FROM tags WHERE ownerid = $ownerid AND leagueid = $leagueid");
    $sth->execute();
     while (my ($curr_playerid, $curr_locked, $curr_active) = $sth->fetchrow_array())
     {
       $can_franchise = 0 if (($curr_locked eq 'yes') && ($curr_active eq 'yes'));
       $existing_frans{$curr_playerid} = $curr_locked if ($in_player_id != $curr_playerid);
     }
    $sth->finish();

    if (($in_player_name !~ /^$/) && (defined $in_tag_type) && ($can_franchise))
    {
      if ($in_lock_status eq 'true')
      {
         $sth = $dbh->prepare("REPLACE INTO tags (playerid,ownerid,type,leagueid,cost,locked,active) VALUES ($in_player_id,$ownerid,'$in_tag_type',$leagueid,'$in_player_cost','yes','yes')");
      }
      else
      {
         $sth = $dbh->prepare("REPLACE INTO tags (playerid,ownerid,type,leagueid,cost) VALUES ($in_player_id,$ownerid,'$in_tag_type',$leagueid,'$in_player_cost')");
      }
   
      $sth->execute() or die "Cannot execute: " . $sth->errstr();
      $sth->finish();
    }

    foreach my $existing_fran (keys %existing_frans)
    {
print LOG "Delete $existing_fran? ";
      if (($existing_frans{$existing_fran} eq 'no') && ($existing_fran ne $in_player_name))
      {
print LOG "YES!\n";
        $sth = $dbh->prepare("DELETE FROM tags WHERE playerid = $existing_fran AND leagueid = $leagueid");
        $sth->execute() or die "Cannot execute: " . $sth->errstr();
        $sth->finish();
      }
print LOG "\n";
    }
  }

close(LOG);

dbDisconnect($dbh);
print "Location: $return\n\n";
