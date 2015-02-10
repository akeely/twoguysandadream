#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use DBI;
use Leagues;
use Session;
use DBTools;
use JSON;

my $cgi = new CGI;

## For UTF-8 characters
binmode(STDOUT, ":iso-8859-1");
print "Cache-Control: no-cache\n";

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) = checkSession();
my $dbh = dbConnect();

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
  $players = "/var/log/fantasy/temp_" . $sport_t . "_players.txt";
   
  open(FILE,"<$players");
  flock(FILE,1);
  @lines=<FILE>;
  close(FILE);
  $size=@lines;


  #Get League Data
  my $league = Leagues->new($league_t,$dbh);
  if (! defined $league)
  {
    die "ERROR - league object not found!\n";
  }

  #Get Team Info
  $sth = $dbh->prepare("SELECT * FROM teams WHERE league = '$league_t' AND name = '$team_t'")
       or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  ($tf_owner, $tf_name, $tf_league, $tf_adds, $tf_sport, $tf_plusminus) = $sth->fetchrow_array();
  $sth->finish();

  print "Content-type: text/html\n\n";
 
print <<EOM;

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


// REQUEST OBJECT
var http = createRequestObject()
var waiting = 0
var rem_row = -1

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
    if (response[0] == 1)
      add_table.rows[rem_row].style.display = 'none'
    
    waiting = 0
    rem_row = -1
    alert(response[1])
  }
}

-->
</script>

 <LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>

</HEAD>
 <BODY>

   <form name="add_form" action="/cgi-bin/fantasy/putPlayer.pl" method="post" target="_top" onsubmit="return parent.add_checker($size)">

   <p align=center>

   <b>If you cannot find a player that you wish to be nominated, please contact the commissioner for manual addition</b>
   <br><br>
   
    <table align=center>
     <tr>
      <td>Available Adds: </td>
      <td><input type=hidden name="Num_Adds"><b>$tf_adds</b>
             
EOM


  $disabled_flag = "";
  if ($tf_adds == 0)
  {
    $disabled_flag = "disabled";
  }

  ##print "<td><input $disabled_flag type='submit' name='player_add'  value='Add Player'>";
  print '</tr>';

  $commish_flag = ($user eq $league->{_OWNER}) ? 1 : 0;


print <<EOM;
    </table>

   <br>
EOM

  if ($size > 0)
  {

print <<EOM;

   <table align=center name="add_table" id="add_table" frame=box>
    <td><b>Rank</b></td>
    <td><b>Player Name</b></td>
    <td><b>Position(s)</b></td>
    <td><b>$tag Team</b></td>
    <td><b></b></td>
   </tr>

EOM

    open(FILE,"<$players");
    flock(FILE,1);

    $sth_get_name = $dbh->prepare("SELECT name FROM players WHERE playerid=?")
                   or die "Cannot prepare: " . $dbh->errstr();
    $count = 1;
    foreach $line (<FILE>)
    {
      chomp($line);
      ($id,$pos,$team,$rank,$league_team) = split(';',$line);
      if ($league_team eq 'NONE')
      {
	  
        $sth_get_name->execute($id) or die "Cannot execute: ". $sth_get_name->errstr();
        $player = $sth_get_name->fetchrow_array();

##<td><input type="radio" name="player_id" value="$id"></td>

print <<EOM;

  <tr>
   <td>$rank</td>
   <td>$player</td>
   <td>$pos</td>
   <td>$team</td>
   <td align="center" style="background-color: #5599cc; text-decoration: none;"><a href="javascript:addPlayer($id,'$player',$commish_flag,$count)" style="text-decoration: none;"><span style="color: #FFFF00; font-size: 150%; line-height: 1; font-weight: bold">+</span></a></td>
  </tr>

EOM
        $count++;

      }
    }
    close(FILE);

    #remove player list from temp-listing file
    open (FILE, ">$players");
     flock(FILE,2);
     print FILE "";
    close(FILE);

  }

print <<EOM;

  </table>
  </form>
 </body>
</html>

EOM

dbDisconnect($dbh);

