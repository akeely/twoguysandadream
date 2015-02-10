#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use DBI;
use CGI  qw/:standard/;
use DBTools;

my %cookies = fetch CGI::Cookie;
my $cookie = $cookies{SESS_ID};
$id = '';
if ($cookie)
{
  $id = $cookie->value;
  $cookie->expires('-1d');
  # Baking cookie sets headers
  print "Set-cookie: $cookie\n";
}

$return = "/cgi-bin/fantasy/getTeam.pl"; 
$errors = "./error_logs/team_errors.txt";

$userAddr = $ENV{REMOTE_ADDR};
## Connect to sessions database
$dbh = dbConnect();
$table = "sessions";
$sth = $dbh->prepare("DELETE FROM $table WHERE sess_id = '$id'")
        or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
my $pwd_check = $sth->fetchrow_array();
$sth->finish();
dbDisconnect($dbh);

open(FILE,">$errors");
flock(FILE,2);
print FILE "<b>Welcome to the Auction Web Site!<br><br></b>\n";
close(FILE);

print "Status: 302 Moved\nLocation: $return\n\n";
