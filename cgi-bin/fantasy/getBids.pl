#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Nav_Bar;
use Leagues;
use DBTools;
use Session;

my $cgi = new CGI;

# files
$bid_error_file = '/var/log/fantasy/bid_errors.txt';
$team_error_file = '/var/log/fantasy/team_errors.txt';

## For UTF-8 characters
binmode(STDOUT, ":iso-8859-1");


########################
#
# Header Print
#
########################

sub Header($$$$)
{
  my $head_user = shift;
  my $head_team = shift;
  my $league_owner = shift;
  my $draft_status = shift;

  my $date_string = `date '+%Y%m%d%H%M%S'`;

print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";

print <<HEADER;

<HTML>
<HEAD>
<TITLE>Auction Page</TITLE>

<!-- INCLUDE JAVASCRIPT FILES HERE!!! AVK 3/11/08 -->
<script src="/fantasy/jquery-2.1.1.js"></script>
<script src="/fantasy/all_js.js?$date_string" language="javascript" type="text/javascript"></script>

<script language="JavaScript">
<!--
   var http = createRequestObject()
   
   var rosters = new Object()
   var current_display_team='$head_team'

   var ourInterval = setInterval("table_loop('$head_user')", 1000);
-->
</script>


<LINK REL=StyleSheet HREF="/fantasy/style.css?$date_string" TYPE="text/css" MEDIA="screen">

</HEAD>

<BODY onLoad="table_loop('$head_user')">
HEADER

  my $is_commish = ($league_owner eq $head_user) ? 1 : 0;
  my $nav = Nav_Bar->new('Auction',"$head_user",$is_commish,$draft_status,"$head_team");
  $nav->print();

}


########################
#
# Header2 Print
#
########################

sub Header2($)
{
  my $submit_val = shift;

print <<HEADER2;
        <div class="pageWrap" id="auctionPage">

          <form name="bid_form" id="bid_form">
HEADER2
          ##<form name="bid_form" id="bid_form" action="/cgi-bin/fantasy/putBids.pl" onSubmit="return pswd_checker($submit_val)" method="post">
}



####################
#
# Print Submit 
#
####################

sub printSubmit()
{
print <<SUBMIT;
            <input type="submit" value="Submit Bids" id=submit1 name=submit1 style="background:yellow;" onClick="sendBids(event)">
            <input type="reset" value="Clear Bids" id=reset1 name=reset1 style="background:red;">
SUBMIT
}


######################
#
# Print Owner
#
######################



sub PrintOwner($$)
{
my $owner = shift;
my $name  = shift;
my $check = shift;

print <<EOM;

  <option value="$owner" $check> 
  $name
  </option>

EOM

}



######################
#
# List Error
#
######################


sub ListError($)
{
my $message = shift;

print <<EOM;

$message

EOM

}


##############
#
# Main Function
#
##############

# variables for players
my @name;
my @pos;
my @bid;
my @bidder;
my @time;
my @team;
my @ez_time;
my $count = 0;
my $total_players = 0;


my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) = checkSession();

my $dbh = dbConnect();

#Get League Data
$league = Leagues->new($league_t,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}
$owner = $league->owner();
$draftStatus = $league->draft_status();
$draftType = $league->draft_type();
$contractStatus = $league->keepers_locked();
$sport = $league->sport();
$use_IP_flag = $league->sessions_flag();
$keeper_increase = $league->keeper_increase();
$keeper_slots_raw = $league->keeper_slots();
 

$players_auction_file = "auction_players";
$players_won_file = "players_won";
$messagefile = "/var/log/fantasy/message_board_$league_t.txt";

Header($user,$team_t,$owner,$draftStatus);

# DB-style

$sth = $dbh->prepare("SELECT COUNT(*) FROM $players_auction_file WHERE league = '$league_t'")
      or die "Cannot prepare: " . $dbh->errstr();
$total_players = $sth->execute() or die "Cannot execute: " . $sth->errstr();
$sth->finish();

Header2($use_IP_flag eq 'yes' ? 1 : 0);

##open(MESSAGES, "<$bid_error_file");
## flock(MESSAGES,1);
## foreach (<MESSAGES>)
## {
##   chomp($_);
##   #print any errors
##   ($myteam, $myleague, $myline) = split(';',$_);
##
##   if ((($myleague eq $league_t) & ($myteam eq $team_t) & ($use_IP_flag eq 'yes')) | ($use_IP_flag eq 'no'))
##   {
##     ListError($myline);
##   }
## }
##close(MESSAGES);



$sth = $dbh->prepare("Select count(1) from teams where league='$league_t'");
$sth->execute();
$team_count = $sth->fetchrow();
$sth->finish();

$dbh->disconnect();

# Display time, remaining budgets and roster spots
print <<EOM;
          <div id="main_div">
            <div id="teamsBlock">
              <table id="stat_table" width="270">
                <tr align=center>
                  <td colspan=5><b>Current Time</b>$time_string</td>
                </tr>
                <tr bgcolor="#5599cc">
                  <td colspan=5></td>
                </tr>
                <tr>
                  <td width="120"><b>Team</b></td>
                  <td><b>Money</b></td>
                  <td><b>Max Bid</b></td>
                  <td><b>Roster</b></td>
                  <td><b>Adds</b></td>
                </tr>
EOM

for (my $x=0; $x<$team_count; $x++)
{

print <<EOM;
                <tr>
                  <td></td>
                  <td></td>
                  <td></td>
                  <td></td>
                  <td></td>
                </tr>
EOM

}



print <<TBL;
                <tr>
                  <td colspan="5">
                  <div id="teamRoster">
                    <table id="teamRoster_table">
                       <tr align="center">
                         <td colspan="3"i id="roster_team_header">$team_t</td>
                       </tr>
                       <tr align=center>
                        <td><b>Player</b></td>
                        <td><b>Cost</b></td>
                        <td><b>Pos</b></td>
                      </tr>
                    </table>
                  </div>
                  </td>
                </tr>
              </table>
            </div>

  <div id="playersBlock"> 
    <div id="submitBidsTop">
            <input type="hidden" name="OWNER" id="OWNER" value="$user">
            <input type="hidden" name="TEAMS" id="TEAMS" value="$team_t">
            <input type="hidden" name="total_players" id="total_players" value="$total_players">
            <input type="hidden" name="league" id="league" value="$league_t">
            <a name="BIDDING"><b>ENTER BIDS &gt; $team_t</b></a>
TBL

printSubmit();

print <<TBL;
    </div>
    <div id="global_errors"></div>
    <table width="690" cellpadding="4" frame="box" id="PLAYER_TABLE_1">
    <tr>
      <th>Player</th>
      <th>Pos</th>
      <th>Team</th>
      <th>High Bid</th>
      <th>Bidder</th>
      <th>Time Remaining</th>
      <th>Target</th>
      <th>Bid</th>
    </tr>
TBL

my $l1 = length($user);
my $l2 = length($owner);

print <<EOM;
</table>
      <div id="submitBidsBottom">
EOM

printSubmit();

print <<EOM;
      </div>
EOM

if ($draftType eq 'rfa')
{
print <<EOM;
      <div id="rfaDraftResults">
        <table width="682" cellpadding="4" id="rfa_table">
          <tr>
            <td colspan="4" align="middle">
              <b>RFA Draft Results</b>
            </td>
          </tr>
          <tr style="font-size: 70%;">
            <td align="middle"><b>Player</b></td>
            <td align="middle"><b>Winning Team</b></td>
            <td align="middle"><b>Owner Overriden?</b></td>
            <td align="middle"><b>Cost</b></td>
          </tr>
        </table>
      </div>
EOM
}

print <<EOM;
    </div>
  </div>
</form>

</div>
</div>

EOM

my $rfa_text = 'Start';
if ($draftType eq 'rfa')
{
  $rfa_text = 'End';
}


if ($user eq $owner)
{
  print "<center style='padding-top:10px'>\n";
  print "<a href='/cgi-bin/fantasy/pause.pl?action=pause'>Pause Draft!</a>\n" if ($draftStatus eq 'open');
  print "<a href='/cgi-bin/fantasy/pause.pl?action=unpause'>Continue Draft!</a>\n" if ($draftStatus eq 'paused');
  print qq{<a style='padding-left:10px' href='javascript:void(0)' $league_t onclick='confirmRfaDraft("$league_t","$rfa_text"); return false;'>$rfa_text RFA Draft</a>};
  print "</center>\n";

}

print <<EOM;
<script src="http://repository.chatwee.com/scripts/62942a3152b372f52757af51e1a52e73.js" type="text/javascript" charset="UTF-8"></script>
</BODY>
</HTML>
EOM

dbDisconnect($dbh);

