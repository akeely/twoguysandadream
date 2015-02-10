#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use DBTools;
use Session;
my $cgi = new CGI;

# script to generate the player addition page

# files
$error_file = "/var/log/fantasy/add_errors.txt";
$team_error_file = "/var/log/fantasy/team_errors.txt";


########################
#
# Header Print
#
########################

sub Header()
{

print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";

print <<HEADER;

<HTML>
<HEAD>
<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
<TITLE>Player Target Addition</TITLE>

<script language="JavaScript">
<!--
function add_checker(list_size)
{
  if (add_form.limit0.value == '')
  {
    alert("Please enter a target value")
    return (false);
  }

  // Check to make sure target price is a number
  var check = '-0123456789'
  for (var i = 0; i < add_form.limit0.length; i++)
  {
    var j
    for (j = 0; j < check.length; j++) 
    {
      if (chr == check[j])
      { 
        j=0
        break
      }
    }
 
    // Should only reach here is a non-numeric entry is used
    if (j == (check.length - 1))
    {
      alert("Your target price must be a number")
      return(false)
    }
  }

  var radio_choice = false;
  // Loop from zero to the one minus the number of radio button selections
  for (counter = 0; counter < add_form.name0.length; counter++)
  {
    // If a radio button has been selected it will return true
    // (If not it will return false)
    if (add_form.name0[counter].checked)
    radio_choice = true; 
  }

  if (!radio_choice)
  {
    // If there were no selections made display an alert box 
    alert("Please select a target player")
    return (false);
  }

  return (true);
}
-->
</script>

</HEAD>
<BODY>
<p align=center><a href="/fantasy/fantasy_main_index.htm">Fantasy Home</a>
<br>

HEADER

}

########################
#
# Footer1 Print
#
########################

sub Footer1($$)
{
my $sport = shift;
my $league = shift;
  
print <<FOOTER1;

<p align=center>
Use the form below to select a new player to be added to your target list.<br>
If you enter a target price less than or equal to zero, that player target will not recorded.<br>This is also a way to remove targets from your list.
<br>
<form action="/cgi-bin/fantasy/parsePlayers.pl" method="post">
<table frame="box" align=center>
  <tr>
    <td>Player Position</td>
    <td>Last Name</td>
    <td>Sort By ESPN Rankings</td>
    <td rowspan="2"><input type="submit" value="Sort Players"></td>
   </tr>
   <tr>

FOOTER1

  if ($sport eq "baseball")
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
  elsif ($sport eq "football")
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
  </tr>
</table>
</form>


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

<input type=hidden name='total' value=0>
</form>
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

$message

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
 <!--$owner-->
 $owner

EOM

}

######################
#
# Print Player
#
######################


sub PrintPlayer($)
{
my $name = shift;

print <<EOM;

 $name<br>

EOM

}


##############
#
# Main Function
#
##############

# variable for error
my $owner;
my $password;
my $name;

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) = checkSession();

my $dbh = dbConnect();

  #Get League Data
  $sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  ($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
  $sth->finish();

  Header();

  PrintHidden($ip);

  open(MESSAGES, "<$error_file");
   flock(MESSAGES,1);
   @LINES=<MESSAGES>;
   chomp (@LINES);
  close(MESSAGES);
  $SIZE=@LINES;

  open(MESSAGES, ">$error_file");
   flock(MESSAGES,2); 
   print MESSAGES "";
  close(MESSAGES);

  for($a=0;$a<$SIZE;$a++)
  {
    #print any errors
    ($myteam, $myleague, $myline) = split(';',$LINES[$a]);
    if ((($myleague eq $league_t) & ($myteam eq $team_t) & ($use_IP_flag eq 'yes')) | ($use_IP_flag eq 'no'))
    {
      ListError($LINES[$a]);
    }
  }

  Footer1($sport_t,$league_t);

  if ($sport_t eq "baseball")
  {
    $tag = 'MLB';
  }
  elsif ($sport_t eq "football")
  {
    $tag = 'NFL';
  }
  $players = "/var/log/fantasy/temp_" . $sport_t . "_players.txt";


  open(FILE,"<$players");
  flock(FILE,1);
  @lines=<FILE>;
  close(FILE);
  $size=@lines;

  if ($size > 0)
  {

print <<EOM;
   <br>
   <form name="add_form" action="/cgi-bin/fantasy/addTarget.pl" method="post" onsubmit="return add_checker($size)">
   <table align=center frame=box>
   <tr align=center>
    <td colspan=2>
     Player Price Limit: <input type="text" size=5 name="limit0" value='0'>
    </td>
    <td colspan=2 align=center>
     <input type="submit" value="Add to Player Targets">
    </td>
   </tr>
   <tr><b>
    <td>Select</td>
    <td>Player Name</td>
    <td>Position(s)</td>
    <td>$tag Team</td>
    <td>ESPN Ranking</td>
   </tr>

EOM

    open(FILE,"<$players");
    flock(FILE,1);

    foreach $line (<FILE>)
    {
      chomp($line);
      ($player,$pos,$team,$rank,$league_team) = split(';',$line);
      if (($league_team eq 'NONE') || ($league_team eq "<b>IN AUCTION</b>"))
      {

print <<EOM;

  <tr>
   <td><input type="radio" name="name0" value="$player"></td>
   <td>$player</td>
   <td>$pos</td>
   <td>$team</td>
   <td>$rank</td>
  </tr>

EOM

      }
    }
    close(FILE);

    # Clear temp file
    open(FILE,">$players");
    flock(FILE,2);
    print FILE "";
    close(FILE);
  }


  Footer3();

  dbDisconnect($dbh);

