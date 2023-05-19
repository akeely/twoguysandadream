#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Nav_Bar;
use Leagues;
use DBTools;
use Session;

my $cgi = new CGI;

# script to generate the commissioner tools pages

# error files
$team_error_file = "/var/log/fantasy/team_errors.txt";


##############
#
# Main Function
#
##############

# variable for error
my $owner;
my $name;

my ($ip,$sess_id,$sport_t,$leagueid, $teamid, $ownerid, $ownername, $teamname) = checkSession();
my $dbh = dbConnect();

#Get League Data
$league = Leagues->new($leagueid,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}
$league_owner = $league->owner();
$league_name = $league->name();
$draftStatus = $league->draft_status();
$contractStatus = $league->keepers_locked();
$use_IP_flag = $league->sessions_flag();
$keeper_increase = $league->keeper_increase();
$keeper_slots_raw = $league->keeper_slots();
$auction_length = $league->auction_length();
$bid_time_extension = $league->bid_time_ext();
$bid_time_buffer = $league->bid_time_buff();
$TZ_offset = $league->tz_offset();
$login_extend_time = $league->login_ext();
dbDisconnect($dbh);

my $is_commish = ($league_owner eq $ownerid) ? 1 : 0;
if (!$is_commish)
{
  open(FILE, ">$team_error_file");
   flock(FILE,2);
   print FILE "<b>You must be the commissioner to access this page!</b>\n";
  close(FILE);
  $return = "/cgi-bin/fantasy/getTeam.pl";
  print "Location: $return\n\n";
}
else
{
  $ip_flag = "";
  if ($use_IP_flag eq 'yes')
  {
    $ip_flag = "checked";
  }

  $contract_flag = "";
  if ($contractStatus eq 'yes')
  {
    $contract_flag = "checked";
  }

  $draftStatus = uc($draftStatus);

##############################
print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";
print <<WELCOME;


<HTML>
<HEAD>
<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
<TITLE>Commissioner Tools</TITLE>


</HEAD>
<BODY>

WELCOME

  my $nav = Nav_Bar->new('Tools',$ownername,$is_commish,$draftStatus,$teamname);
  $nav->print();

print <<WELCOME;

<p align=middle>Welcome, Commissioner. Below are the configuration tools for you league.<br>Change them as you see fit
<br><br><br>

<form action="/cgi-bin/fantasy/putTools.pl" method="post">
<b>Attributes</b>
<center>
<table align=middle>
 <tr> 
  <td align=middle><b>League Attribute</b></td>
  <td align=middle><b>Current State</b></td>
 </tr>
 <tr>
  <td align=middle>Player Auction Length (minutes)</td>
  <td align=middle><input type="text" name="auction_length" value="$auction_length" maxlength="4"></td>
 </tr>
 <tr>
  <td align=middle>Bid Time Extension (minutes)</td>
  <td align=middle><input type="text" name="bid_extension" value="$bid_time_extension" maxlength="3"></td>
 </tr>
 <tr>
  <td align=middle>Bid Time Buffer (minutes)</td>
  <td align=middle><input type="text" name="bid_buffer" value="$bid_time_buffer" maxlength="3"></td>
 </tr>
 <tr>
  <td align=middle>Time Zone Offset (Hours)</td>
  <td align=middle><input type="text" name="tz_offset" value="$TZ_offset" maxlength="3"></td>
 </tr>
 <tr>
  <td align=middle>Login Time Extension (minutes)</td>
  <td align=middle><input type="text" name="login_extension" value="$login_extend_time" maxlength="3"></td>
 </tr>
 <tr>
  <td align=middle>IP Tracking Flag</td>
  <td align=middle><input type="checkbox" name="ip_flag" value="true" $ip_flag></td>
 </tr>
 <tr>
  <td align=middle>League $league_name Contract Signing Lock</td>
  <td align=middle><input type="checkbox" name="contract_flag" value="true" $contract_flag></td>
 </tr>
 <tr>
  <td colspan=2 align=middle><input type="submit" value="Update League Configuration"></td>
 </tr>
</table>
</form>

<br><br>

<b>Close Auction</b>
<table align=middle>
 <tr> 
  <td align=middle><b>Action</b></td>
  <td align=middle><b>Description</b></td>
  <td align=middle><b>Auction Status</b></td>
 </tr>
 <tr> 
  <td align=middle><a href='/cgi-bin/fantasy/close_auction.pl'><font color="blue">Close Auction</font></a></td>
  <td align=middle>Officially close the auction - loads draft results to<br>'final_rosters' for updating by 'Update Rosters' below</td>
  <td align=middle><b>$draftStatus</b></td>
 </tr>
</table>

<br><br>

</p>

</BODY>
</HTML>

WELCOME
##############################

}

