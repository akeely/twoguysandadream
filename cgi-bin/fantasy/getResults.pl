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
my $dbh = dbConnect();

## For UTF-8 characters
binmode(STDOUT, ":iso-8859-1");


######################
#
# Print Owner
#
######################

sub Print_Player($$$$$)
{
  my $player   = shift;
  my $owner    = shift;
  my $position = shift;
  my $cost     = shift;
  my $time     = shift;

  if ($time =~ /^$/)
  {
    $time = "KEEPER CONTRACT";
  }

print <<EOM;

 <tr>
  <td>$player</td>
  <td>$owner</td>
  <td>$position</td>
  <td>$cost</td>
  <td>$time</td>
 </tr>

EOM

}


my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();

  #Get League Data
  $league = Leagues->new($league_t,$dbh);
  if (! defined $league)
  {
    die "ERROR - league object not found!\n";
  }

  print "Cache-Control: no-cache\n";
  print "Content-type: text/html\n\n";

print <<HEADER;

<HTML>
<HEAD>

<script language="JavaScript">
<!--
function createRequestObject() {

    var ro;
    try
    {
        // Firefox, Opera 8.0+, Safari
        ro = new XMLHttpRequest();
    }
    catch (e)
    {
       // Internet Explorer
       try
       {
          ro = new ActiveXObject("Msxml2.XMLHTTP");
       }
       catch (e)
       {
          try
          {
             ro = new ActiveXObject("Microsoft.XMLHTTP");
          }
          catch (e)
          {
             alert("ERROR: Your browser does not support AJAX!");
             return false;
          }
       }
    }
    return ro;
}


   var http = createRequestObject()
   var order = "asc"
   var order2 = "desc"


function sort_list(field, league)
{

  // If its the same field, switch the sort order
  if (field == hidden_form.sorted.value)
  {
    order3 = order
    order = order2
    order2 = order3
  }

  if (hidden_form.can_proceed.value == 'false')
  {
    alert("Please wait for the previous sort to finish")
    return(false)
  }

  var action = field + ";" + league + ";" + order
  http.open('GET','sortResults.pl?action='+action)
  http.onreadystatechange = redo_list
  http.send(null)

  hidden_form.can_proceed.value = false
  hidden_form.sorted.value = field

}


function redo_list()
{

  if(http.readyState == 4)
  {
    var response = http.responseText
    var lines = new Array();

    lines = response.split(';')
            
    var temp
    for (var i = 1; i < (lines.length); i++)
    {
      temp = lines[i].split(',')
     
      auction_table.rows[i].cells[0].innerHTML = temp[0];
      auction_table.rows[i].cells[1].innerHTML = temp[1];
      auction_table.rows[i].cells[2].innerHTML = temp[2];
      auction_table.rows[i].cells[3].innerHTML = temp[3];
      auction_table.rows[i].cells[4].innerHTML = temp[4];
    }

    hidden_form.can_proceed.value = true

  }

}


function change_text(cell_num, flag)
{
  if (flag == 1)
  {
    auction_table.rows[0].cells[cell_num].style.color = "#348781"
  }
  else
  {
    auction_table.rows[0].cells[cell_num].style.color = "#000000"
  }
}
-->
</script>


<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" 
MEDIA=screen>
<TITLE>Draft Results - League $league_t</TITLE>
</HEAD>
<BODY>
<p align="center">
<center>

HEADER

  my $is_commish = ($league->owner() eq $user) ? 1 : 0;
  my $nav = Nav_Bar->new('Draft Results',"$user",$is_commish,$league->draft_status(),"$team_t");
  $nav->print();

print <<HEADER;

<br>
<h3>Draft Results - League $league_t</h3>

The draft results for your league are shown below. 
<br>Each column is sortable - simply click header of the column by which you would like to sort.
<br><br>

<table id="auction_table">
 <tr align=center>
  <td onclick="sort_list('name', '$league_t')" onMouseOver="change_text(0,1)" onMouseOut="change_text(0,0)"><b>Player</b></td>
  <td onclick="sort_list('team', '$league_t')" onMouseOver="change_text(1,1)" onMouseOut="change_text(1,0)"><b>Owner</b></td>
  <td onclick="sort_list('position', '$league_t')" onMouseOver="change_text(2,1)" onMouseOut="change_text(2,0)"><b>Position</b></td>
  <td onclick="sort_list('price', '$league_t')" onMouseOver="change_text(3,1)" onMouseOut="change_text(3,0)"><b>Cost</b></td>
  <td onclick="sort_list('time', '$league_t')" onMouseOver="change_text(4,1)" onMouseOut="change_text(4,0)"><b>Time</b></td>
 </tr>

HEADER


  $sth = $dbh->prepare("SELECT p.name,w.price,w.team,w.time,p.position FROM players_won w, players p WHERE league = '$league_t' and w.name=p.playerid ORDER BY w.time, p.position");
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
 
  while( ($player,$cost,$owner,$time,$position) = $sth->fetchrow_array())
  {
    $time_string = '';
    if (($time ne '') && ($time ne 'RFA'))
    {
      ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime($time);
      $Year += 1900;
      $Month++;
      $Month = "0" . $Month if ($Month < 10);
      $Day = "0" . $Day if ($Day < 10);
      $Hour = "0" . $Hour if ($Hour < 10);
      $Minute = "0" . $Minute if ($Minute < 10);
      $Second = "0" . $Second if ($Second < 10);
      $time_string = "$Month/$Day/$Year at $Hour:$Minute:$Second";
    }
    elsif (time ne '')
    {
      ## Allow for overrides like RFA, etc
      $time_string = $time;
    }
    Print_Player($player, $owner, $position, $cost, $time_string);
  }
  $sth->finish();

  dbDisconnect($dbh);


print <<FOOTER;

</Table>

<form name="hidden_form">
  <input type="hidden" name="sorted" value="time">
  <input type="hidden" name="can_proceed" value="true">
</form>

</p>
</center>
</Body>
</HTML>

FOOTER


if (1) {
exit;
}
