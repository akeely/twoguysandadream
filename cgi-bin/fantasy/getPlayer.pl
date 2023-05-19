#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Nav_Bar;
use Leagues;
use Session;
use DBTools;
my $cgi = new CGI;

# script to generate the player addition page

# files
$team_error_file = "/var/log/fantasy/team_errors.txt";
$error_file = "/var/log/fantasy/add_errors.txt";


########################
#
# Header Print
#
########################

sub Header($$$$)
{

  my $head_user = shift;
  my $head_team = shift;
  my $is_commish = shift;
  my $draft_status = shift;

  my $date_string = `date '+%Y%m%d%H%M%S'`;

  print "Cache-Control: no-cache\n";
  print "Content-type: text/html\n\n";

  print <<HEADER;

<HTML>
<HEAD>

<TITLE>Player Addition</TITLE>
<!-- INCLUDE JAVASCRIPT FILES HERE!!! AVK 3/11/08 -->
<script src="/fantasy/jquery-2.1.1.js"></script>
<script src="/fantasy/all_js.js?$date_string" language="javascript" type="text/javascript"></script>
<script language="JavaScript">
// REQUEST OBJECT
var http = createRequestObject()
var waiting = 0
var rem_row = -1

function fetchPlayers(ev) {
  ev.preventDefault();

  if (\$("#player_form :submit").get(0).disabled == true) {
    return;
  }
  
  // disable input button while loading
  \$("#player_form :submit").get(0).disabled=true;
  \$("#fetchStatus").show();

  \$.ajax({
           type: "POST",
           url: "/cgi-bin/fantasy/parsePlayers.pl",
           dataType: "json",
           data: \$("#player_form").serialize(), // serializes the form's elements.
           success: function(response)
           {
             \$('#add_table').find("tr:gt(0)").remove();
             \$('#add_display').html(response.ADDS);
             var row = 1;
             if (response.PLAYERS) {
               \$.each(response.PLAYERS, function(rownum, playerObject) {
                 if (playerObject.CAN_ADD !== 1) {
                   return true;
                 }

                 \$('#add_table tr:last').after('<tr><td>' + playerObject.RANK + '</td><td>' + playerObject.NAME + '</td><td>' + playerObject.POSITION + '</td><td>' + playerObject.TEAM + '</td><td align="center" style="background-color: #5599cc; text-decoration: none;"><a href="javascript:addPlayer(' + playerObject.ID + ',&quot;' + playerObject.NAME + '&quot;,$is_commish,'+ row + ')" style="text-decoration: none;"><span style="color: #FFFF00; font-size: 150%; line-height: 1; font-weight: bold">+</span></a></td></tr>');
                 row = row+1;
               });
             } else {
               \$('#add_table tr:last').after('<tr><td colspan=5 align="center"><b>NO RESULTS FOUND</b></td></tr>');
             }

             \$("#player_form :submit").get(0).disabled=false;
             \$("#fetchStatus").hide();
           },
           error: function(a,b,c) {
             alert("Well shit");
             \$("#player_form :submit").get(0).disabled=false;
             \$("#fetchStatus").hide();
           }
  });

}


function addPlayer(id,name,commish,row)
{
  if (waiting == 1)
  {
    alert("Please to wait for your previous player add to finish!")
    return;
  }

  add = confirm("Add "+name+" to the Auction Page?")
  if (add != false)
  {
    commish_add=false
    if (commish == 1)
    {
      commish_add = confirm("Add "+name+" as a Commissioner entry?")
    }
    waiting = 1
    rem_row = row
    http.open('GET',encodeURI('putPlayer.pl?player_id='+id+'&commish_flag='+commish_add))
    http.onreadystatechange = printMessage
    http.send(null)
  }
}

function printMessage()
{
  if(http.readyState == 4)
  {
    var response = http.responseText.split(';')
    if (response[0] == 1) {
      add_table.rows[rem_row].style.display = 'none'
      var num_adds = \$('#add_display').html();
      \$('#add_display').html(num_adds - 1);
    }
    
    waiting = 0
    rem_row = -1
    alert(response[1])
  }
}
</script>
<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>

</HEAD>
<BODY onLoad="fetchPlayers(event)">

<p align=center>

HEADER

  my $nav = Nav_Bar->new('Player Add',"$head_user",$is_commish,$draft_status,"$head_team");
  $nav->print();

}

########################
#
# Header2 Print
#
########################

sub Header2()
{

print <<HEADER2;

<br>

HEADER2

}

########################
#
# Footer1 Print
#
########################

sub Footer1($$$$$$)
{
my $sport_t = shift;
my $league_t = shift;
my $team_t = shift;
my $is_commish = shift;
my $draft_type = shift;
my $num_adds = shift;
  
print <<FOOTER1;

<p align=center>
<form id="player_form">
<input type="hidden" name="team" id="team" value="$team_t">
<input type="hidden" name="league" id="league" value="$league_t">
<table frame="box" align=center>
  <tr>
   <td>Player Position</td>
   <td>Last Name</td>
   <td>Sort By Yahoo Rankings</td>
FOOTER1

if ($is_commish)
{
  print "   <td>RFA Only</td>\n";
}

print <<FOOTER1;

  </tr>
  <tr>

FOOTER1

  if ($sport_t eq 'baseball')
  {

print <<EOM;

   <td align=center><select name="position">
        <option value="ALL">ALL</option>
        <option value="C">C</option>
        <option value="1B">1B</option>
        <option value="2B">2B</option>
        <option value="3B">3B</option>
        <option value="SS">SS</option>
        <option value="OF">OF</option>
        <option value="Util">Util</option>
        <option value="SP">SP</option>
        <option value="RP">RP</option>
        <option value="P">P</option>
       </select>
    </td>

EOM

  }
  elsif ($sport_t eq 'football')
  {

print <<EOM;

   <td align=center><select name="position">
        <option value="ALL">ALL</option>
        <option value="QB">QB</option>
        <option value="RB">RB</option>
        <option value="WR">WR</option>
        <option value="TE">TE</option>
        <option value="K">K</option>
        <option value="DEF">DEF</option>
       </select>
    </td>

EOM

  }
  
print <<EOM;

   <td align=center><select name="name">
        <option value="ALL">ALL</option>
        <option value="A">A</option>
        <option value="B">B</option>
        <option value="C">C</option>
        <option value="D">D</option>
        <option value="E">E</option>
        <option value="F">F</option>
        <option value="G">G</option>
        <option value="H">H</option>
        <option value="I">I</option>
        <option value="J">J</option>
        <option value="K">K</option>
        <option value="L">L</option>
        <option value="M">M</option>
        <option value="N">N</option>
        <option value="O">O</option>
        <option value="P">P</option>
        <option value="Q">Q</option>
        <option value="R">R</option>
        <option value="S">S</option>
        <option value="T">T</option>
        <option value="U">U</option>
        <option value="V">V</option>
        <option value="W">W</option>
        <option value="X">X</option>
        <option value="Y">Y</option>
        <option value="Z">Z</option>
       </select>
   </td>
EOM

if ($is_commish)
{
  my $rank_checked = 'checked';
  my $rfa_checked = '';
  if ($draft_type eq 'rfa') {
    $rfa_checked = 'checked';
    $rank_checked = '';
  }
  print qq{   <td align=center><input type=checkbox name="ranked" id="ranked" value='on' onclick="this.clicked=document.getElementById('rfa').checked? this.checked=0 : this.checked=this.checked;" $rank_checked></td>};
  print qq{   <td align=center><input type=checkbox name='rfa' id='rfa' value='on' onclick="document.getElementById('ranked').checked= this.checked? 0 : document.getElementById('ranked').checked; document.getElementById('ranked').disabled=this.checked? 1 : 0;" $rfa_checked></td>};
}
else
{
  print qq{   <td align=center><input type=checkbox name="ranked" id="ranked" value='on' checked></td>};
}

my $tag;
if ($sport_t eq 'baseball')
{
  $tag = 'MLB';
}
elsif ($sport_t eq 'football')
{
  $tag = 'NFL';
}
elsif ($sport_t eq "basketball")
{
  $tag = 'NBA';
}

print <<EOM;

  </tr>
 </table>
<center>
<br><input type="submit" value="Sort Players" onClick="fetchPlayers(event)">
<div id="fetchStatus" style="display:none; font-weight: 700">Fetching Results ...</div>
</center>
</form>
<br>
<p align=center>

<b>If you cannot find a player that you wish to be nominated, please contact the commissioner for manual addition</b>
<br><br>

<table align=center>
 <tr>
  <td>Available Adds: </td>
  <td id="add_display" style="font-weight:bold">$num_adds</td>
 </tr>
</table>

<table align=center name="add_table" id="add_table" frame=box>
   <tr>
    <td><b>Rank</b></td>
    <td><b>Player Name</b></td>
    <td><b>Position(s)</b></td>
    <td><b>$tag Team</b></td>
    <td><b></b></td>
   </tr>
</table>

EOM

}


########################
#
# Footer3 Print
#
########################

sub Footer3()
{
print <<FOOTER3;

</p>
</BODY>
</HTML>

FOOTER3

}

######################
#
# Print Hidden
#
######################


sub PrintHidden($)
{
my $field = shift;

print <<EOM;

<input type="hidden" name="session" value="$field">

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

<p align=center>
$message
</p>

EOM

}


######################
#
# Print Owner
#
######################


sub PrintOwner($)
{
my $owner = shift;

print <<EOM;

 <option value="$owner">
 $owner

EOM

}


##############
#
# Main Function
#
##############

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) =checkSession();
my $dbh = dbConnect();

#Get League Data
$league = Leagues->new($league_t,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}
$owner = $league->owner();
$draftStatus = $league->draft_status();
$contractStatus = $league->keepers_locked();
$sport = $league->sport();
$use_IP_flag = $league->sessions_flag();
$keeper_increase = $league->keeper_increase();
$keeper_slots_raw = $league->keeper_slots();
$draft_type = $league->draft_type();

#Get Team Info
$sth = $dbh->prepare("SELECT * FROM teams WHERE league = '$league_t' AND name = '$team_t'")
     or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($tf_owner, $tf_name, $tf_league, $tf_adds, $tf_sport, $tf_plusminus) = $sth->fetchrow_array();
$sth->finish();

my $is_commish = ($owner eq $user) ? 1 : 0;
Header($user,$team_t,$is_commish,$draftStatus);

PrintHidden($ip);
Header2(); 

open(MESSAGES, "<$error_file");
 flock(MESSAGES,1);
 @LINES=<MESSAGES>;
 chomp (@LINES);
close(MESSAGES);
$SIZE=@LINES;

## Clear error message file
open(MESSAGES, ">$error_file");
 flock(MESSAGES,1); 
 print MESSAGES "";
close(MESSAGES);


for($a=0;$a<$SIZE;$a++)
{ 
  #print any errors
  ($myteam, $myleague, $myline) = split(';',$LINES[$a]);
  if ((($myleague eq $league_t) & ($myteam eq $team_t) & ($use_IP_flag eq 'yes')) | ($use_IP_flag eq 'no'))
  {
    ListError($myline);
  }

}

Footer1($sport_t,$league_t,$team_t,$is_commish,$draft_type,$tf_adds);

Footer3();

dbDisconnect($dbh);
