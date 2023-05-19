#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use DBTools;
use Session;

my $cgi = new CGI;

my ($ip,$sess_id,$sport_t,$leagueid, $teamid, $ownerid, $ownername, $teamname) = checkSession();

my $dbh = dbConnect();

## Set league draft status to 'closed'
$sth = $dbh->prepare("update leagues set draft_status='closed' WHERE id = $leagueid")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
$sth->finish();

$sth = $dbh->prepare("insert into final_rosters (playerid, price, teamid, time, leagueid) (select pw.playerid, pw.price, pw.teamid, pw.time, pw.leagueid from players_won pw where pw.leagueid=$leagueid and not exists (select 'x' from final_rosters f where f.playerid=pw.playerid and f.leagueid=$leagueid))")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
$sth->finish();

dbDisconnect($dbh);

print "Location: /cgi-bin/fantasy/getTools.pl\n\n";
