#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Session;
use DBTools;

my $cgi = new CGI;

#variables that will be used later.
$return = "/cgi-bin/fantasy/teamHome.pl"; 
$team_error_file = "/var/log/fantasy/team_errors.txt";
$errorflag=0;

$in_count_in = $cgi->param('count_in');
$in_count_out = $cgi->param('count_out');
$in_receiver = $cgi->param('receiver');
$in_proposer = $cgi->param('proposer');

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();
my $dbh = dbConnect();

#Get League Data
$sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
$sth->finish();

$trades = "/var/log/fantasy/trades_$league_t.txt";


$num_in = $in_count_in; #num players to get
$count_in=0;
$num_out = $in_count_out; #num players to give up
$count_out=0;

$ids_in = '';
$cost_in = 0;
for($x=0;$x<=$num_in;$x++)
{
  ## get the players to be acquired\
   $test = $cgi->param("in$x");
   if ($test !~ /^$/)
   {
    $cost_in += $cgi->param("costin$x");
    $count_in++;
    $ids_in = "$ids_in$test:";
   }
}
chop($ids_in);

$cost_out = 0;
$ids_out = '';
for($x=0;$x<=$num_out;$x++)
{
  ## get the players to be acquired
   $test = $cgi->param("out$x");
   if ($test !~ /^$/)
   {
    $cost_out += $cgi->param("costout$x");
    $count_out++;
    $ids_out = "$ids_out$test:";
   }
}
chop($ids_out);

open (MSG,">>$trades");
flock(MSG,2);
   print MSG "$in_receiver;$in_proposer;$count_in;$cost_in;$ids_in;$count_out;$cost_out;$ids_out\n";
close (MSG);

dbDisconnect($dbh);
print "Location: $return\n\n";
