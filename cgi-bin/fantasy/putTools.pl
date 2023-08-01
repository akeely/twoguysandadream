#!/usr/bin/perl
use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use Session;
use DBTools;
use Leagues;

my $cgi = new CGI;

#
# script to change the league configurations
#

# files
$return = "/cgi-bin/fantasy/getTools.pl";


## Input Variables
$in_ip_flag = $cgi->param('ip_flag');
$in_contract_flag = $cgi->param('contract_flag');
$in_auction_length = $cgi->param('auction_length');
$in_bid_extension = $cgi->param('bid_extension');
$in_bid_buffer = $cgi->param('bid_buffer');
$in_tz_offset = $cgi->param('tz_offset');
$in_login_extension = $cgi->param('login_extension');

my ($ip,$sess_id,$sport_t,$leagueid, $teamid, $ownerid, $ownername, $teamname) = checkSession();
my $dbh = dbConnect();

#Get League Data
$league = Leagues->new($leagueid,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}
$league_owner = $league->owner();
$draftStatus = $league->draft_status();
$contractStatus = $league->keepers_locked();
$sport = $league->sport();
$use_IP_flag = $league->sessions_flag();
$keeper_increase = $league->keeper_increase();
$keeper_slots_raw = $league->keeper_slots();
$league_name = $league->name();

$new_ip_flag = 'no';
if ("$in_ip_flag" eq 'true')
{
  $new_ip_flag = 'yes';
}

$new_contract_flag = 'no';
if ("$in_contract_flag" eq 'true')
{
  $new_contract_flag = 'yes';
}

#Rewrite Appropriate League File
$sth = $dbh->prepare("UPDATE leagues SET keepers_locked = '$new_contract_flag', auction_length = '$in_auction_length', bid_time_ext = '$in_bid_extension', bid_time_buff = '$in_bid_buffer', tz_offset = '$in_tz_offset', login_ext = '$in_login_extension', sessions_flag = '$new_ip_flag' WHERE id = $leagueid") or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
$sth->finish();

dbDisconnect($dbh);


print "Location: $return\n\n";
