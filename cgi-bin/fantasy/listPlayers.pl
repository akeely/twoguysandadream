#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Nav_Bar;
use Session;
use DBTools;

my $cgi = new CGI;

print "Cache-Control: no-cache\n";

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();

my $dbh = dbConnect();

  #Get League Data
  $sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  ($league_name,$password,$league_owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
  $sth->finish();

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

  my %is_checked = ( 'draft' => '', 'final' => '' );
  my $whichone = `head -1 $players`;
  chomp($whichone);
  $is_checked{$whichone} = 'checked' if (defined $is_checked{$whichone});

  print "Content-type: text/html\n\n";
print <<EOM;

<HTML>
   <HEAD>
      <TITLE>View Player Lists</TITLE>
      <script src="/fantasy/jquery-2.1.1.js"></script>
      <script language="JavaScript">
      function fetchPlayers(ev) {
        ev.preventDefault();

        \$.ajax({
           type: "POST",
           url: "/cgi-bin/fantasy/parsePlayers.pl",
           dataType: "json",
           data: \$("#player_form").serialize(), // serializes the form's elements.
           success: function(response)
           {
             \$('#player_table').find("tr:gt(0)").remove();
             \$.each(response.PLAYERS, function(rownum, playerObject) {
               \$('#player_table tr:last').after('<tr><td>' + playerObject.NAME + '</td><td>' + playerObject.POSITION + '</td><td>' + playerObject.TEAM + '</td><td>' + playerObject.OWNER + '</td><td>' + playerObject.COST + '</td><td>' + playerObject.RANK + '</td></tr>');
             });
           },
           error: function(a,b,c) {
             alert("Well shit: " + a + ", " + b + ", " + c);
           }
        });
      }
      </script>

      <LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
   </HEAD>
   <BODY onload="fetchPlayers(event)">

<p align=center>

EOM

  my $is_commish = ($league_owner eq $user) ? 1 : 0;
  my $nav = Nav_Bar->new('Player List',$user,$is_commish,$draftStatus,$team_t);
  $nav->print();

print <<EOM;

      <hr width="85%">
      <p align="center">Select the position that you wish to view:
         <form id='player_form'>
<table frame="box" align=center>
  <tr>
   <td>Player Position</td>
   <td>Last Name</td>
   <td>Sort By Yahoo! Rankings</td>
   <td>Timeframe</td>
  </tr>
  <tr>

EOM

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
   <td align=center><input type=checkbox name="ranked" value='on' checked></td>
   <td>
    <input type="radio" name="timeframe" value='draft' $is_checked{'draft'}>Post Draft<br>
    <input type="radio" name="timeframe" value='final' $is_checked{'final'}>End Of Season<br>
   </td>
  </tr>
 </table>
            <br>
            <center>
            <input type="submit" value="Continue" onClick="fetchPlayers(event)">
            </center>
      </p>
      </form>
  <table id='player_table' align=center frame=box>
  <tr><b>
    <td>Player Name</td>
    <td>Position(s)</td>
    <td>$tag Team</td>
    <td>League Team</td>
    <td>Cost</td>
    <td>Yahoo! Ranking</td>
  </tr>

EOM

$sth_get_name = $dbh->prepare("SELECT name FROM players WHERE playerid=?") or die "Cannot prepare: " . $dbh->errstr();

open(FILE,"<$players");
flock(FILE,1);
foreach $line (<FILE>)
{
  chomp($line);
  if ($line =~ /;/)
  {
    ($id,$pos,$team,$rank,$league_team,$cost) = split(';',$line);

    $sth_get_name->execute($id);
    $player = $sth_get_name->fetchrow();

print <<EOM;

    <tr>
     <td>$player</td>
     <td>$pos</td>
     <td>$team</td>
     <td>$league_team</td>
     <td>$cost</td>
     <td>$rank</td>
    </tr>

EOM
  }
}
close(FILE);
$sth_get_name->finish();
dbDisconnect($dbh);

print <<EOM;

  </table>
 </body>
</html>

EOM

#clear the temp file
open(FILE,">$players");
flock(FILE,1);
print FILE "";
close(FILE);

