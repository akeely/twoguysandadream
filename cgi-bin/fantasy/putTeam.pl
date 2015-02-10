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
$team_home = "/cgi-bin/fantasy/teamHome.pl";
$get_team = "/cgi-bin/fantasy/logout.pl";
$return = $get_team;

my @values = checkSession();
my $id = $values[3];

my $dbh = dbConnect();

  ($team_t,$sport_t,$league_t) = split(':',$cgi->param('user_sport'));

  $sth = $dbh->prepare("UPDATE sessions SET team = '$team_t', sport = '$sport_t', league = '$league_t' WHERE sess_id = '$id'") or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  $sth->finish();
  dbDisconnect($dbh);

  $return = $team_home;

  print "Location: $return\n\n";
