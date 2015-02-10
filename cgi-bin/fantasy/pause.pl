#!/usr/bin/perl
use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use DBTools;
use Session;

($string1, $action) = split('=',$ENV{'QUERY_STRING'});
$string2 =~ s/%20/ /g;

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();
my $dbh = dbConnect();

#Get League Data
$sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
$sth->finish();

#time stuff.
my $new_end_time = time() + (60 * $auction_length);

if ($action eq 'pause')
{
  $sth_update_league = $dbh->prepare("update leagues set draft_status='paused' where name='$league_t'");
  $sth_update_league->execute();
  $sth_update_league->finish();
}
else
{
$sth_update = $dbh->prepare("update auction_players set time='$new_end_time' where league='$league_t'");
$sth_update->execute();
$sth_update->finish();

$sth_update_league = $dbh->prepare("update leagues set draft_status='open' where name='$league_t'");
$sth_update_league->execute();
$sth_update_league->finish();
}

$dbh->commit();

dbDisconnect($dbh);

print "Location: /cgi-bin/fantasy/getBids.pl\n\n";
exit;

