#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Session;
use DBTools;
my $cgi = new CGI;

#variables that will be used later.
$team_error_file = "/var/log/fantasy/team_errors.txt";
$contracts_page = "/cgi-bin/fantasy/getContracts.pl";
$get_team = "/cgi-bin/fantasy/logout.pl";
$return = $get_team;

my ($ip,$sess_id,$sport_t,$leagueid, $teamid, $ownerid, $ownername, $teamname) = checkSession();
my @values = checkSession();
my $id = $values[3];

my $dbh = dbConnect();

  ($team_t,$sport_t,$league_t) = split(':',$cgi->param('user_sport'));

  $sth = $dbh->prepare("UPDATE sessions SET teamid = $team_t, sport = '$sport_t', leagueid = $league_t WHERE sess_id = '$sess_id'") or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  $sth->finish();
  dbDisconnect($dbh);

  $return = $contracts_page;

  print "Location: $return\n\n";
