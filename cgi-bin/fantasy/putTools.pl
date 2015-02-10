#!/usr/bin/perl
use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use Session;
use DBTools;

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

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();
my $dbh = dbConnect();

#Get League Data
$sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
$sth->finish();

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
$sth = $dbh->prepare("UPDATE leagues SET keepers_locked = '$new_contract_flag', auction_length = '$in_auction_length', bid_time_ext = '$in_bid_extension', bid_time_buff = '$in_bid_buffer', tz_offset = '$in_tz_offset', login_ext = '$in_login_extension', sessions_flag = '$new_ip_flag' WHERE name = '$league_t'") or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
$sth->finish();

dbDisconnect($dbh);


print "Location: $return\n\n";
