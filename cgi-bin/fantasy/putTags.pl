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
$errorflag=0;
$log = "./putTags_log.txt";

open (FILE,">$error_file"); 
       flock(FILE,2);
       print FILE " ";
      close(FILE);


## Input variables
$team = $cgi->param('TEAMS');
$in_TEAM_PASSWORD = $cgi->Param('TEAM_PASSWORD');
$in_league = $cgi->param('league');
$in_lock_status = $cgi->param('LOCK_ME');
$in_tag_type = $cgi->param('tag_type');
$in_player_name = $cgi->param('player_name');
$in_player_cost = $cgi->param('player_cost');
$in_player_pos = $cgi->param('player_pos');
$in_player_id = $cgi->param("$in_player_name" . "_id");

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();
my $dbh = dbConnect();

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

  if($owner ne $team)
  {
    $errorflag=1;
    $return = "/cgi-bin/fantasy/getTags.pl";
    open (FILE,">>$error_file"); 
     flock(FILE,2);
     print FILE "$team_t;$league_t;<b>Your Password is Incorrect!</b>\n";
    close(FILE);
  }
}

open(LOG,">$log");
print LOG "in_league - $in_league\n";
print LOG "in_lock_status - $in_lock_status\n";
print LOG "in_tag_type - $in_tag_type\n";
print LOG "in_player_name - $in_player_name\n";
print LOG "in_player_cost - $in_player_cost\n";
print LOG "in_player_pos - $in_player_pos\n";
print LOG "in_player_id - $in_player_id\n";

if ($errorflag == 0)
{
  print LOG "NO ERRORS!\n";

  ## If owner selects 'NONE' - make sure their tag is clear (unless it was already locked)
  if ($in_player_name eq 'NONE')
  {
    $sth = $dbh->prepare("DELETE FROM tags WHERE team = '$team' and league = '$league_t' and locked='no'");
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    $sth->finish();
  }
  else
  {
    my %existing_frans;
    my $can_franchise = 1;
    $sth = $dbh->prepare("SELECT player, locked, active FROM tags WHERE team = '$team' AND league = '$league_t'");
    $sth->execute();
     while (my ($curr_name, $curr_locked, $curr_active) = $sth->fetchrow_array())
     {
       $can_franchise = 0 if (($curr_locked eq 'yes') && ($curr_active eq 'yes'));
       $existing_frans{$curr_name} = $curr_locked if ($in_player_id ne $curr_name);
     }
    $sth->finish();

    if (($in_player_name !~ /^$/) && (defined $in_tag_type) && ($can_franchise))
    {
      if ($in_lock_status eq 'true')
      {
         $sth = $dbh->prepare("REPLACE INTO tags VALUES ('$in_player_id','$team','$in_tag_type','$league_t','$in_player_cost','yes','yes')");
      }
      else
      {
         $sth = $dbh->prepare("REPLACE INTO tags (player,team,type,league,cost) VALUES ('$in_player_id','$team','$in_tag_type','$league_t','$in_player_cost')");
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
        $sth = $dbh->prepare("DELETE FROM tags WHERE player = '$existing_fran' AND league = '$league_t'");
        $sth->execute() or die "Cannot execute: " . $sth->errstr();
        $sth->finish();
      }
print LOG "\n";
    }
  }
}

close(LOG);

dbDisconnect($dbh);
print "Location: $return\n\n";
