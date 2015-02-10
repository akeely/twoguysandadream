#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use DBTools;
use Session;

my $cgi = new CGI;


my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) = checkSession();

my $dbh = dbConnect();

## Set league draft status to 'closed'
$sth = $dbh->prepare("update leagues set draft_status='closed' WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
$sth->finish();

$sth = $dbh->prepare("insert into final_rosters (select pw.name, pw.price, pw.team, pw.time, pw.league from players_won pw where pw.league='$league_t' and not exists (select 'x' from final_rosters f where f.name=pw.name and f.league='$league_t'))")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
$sth->finish();

dbDisconnect($dbh);

print "Location: /cgi-bin/fantasy/getTools.pl\n\n";
