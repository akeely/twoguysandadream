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

  print "Cache-Control: no-cache\n";
  print "Content-type: text/html\n\n";

  print <<HEADER;

<HTML>
<HEAD>

<TITLE>Player Addition</TITLE>
<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>

</HEAD>
<BODY>

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

sub Footer1($$$$)
{
my $sport_t = shift;
my $league_t = shift;
my $is_commish = shift;
my $draft_type = shift;
  
print <<FOOTER1;

<p align=center>
<form action="/cgi-bin/fantasy/parsePlayers.pl" method="post" target="_top">
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

print <<EOM;

  </tr>
 </table>
<center>
<br><input type="submit" value="Sort Players">
</center>
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

Footer1($sport_t,$league_t,$is_commish,$draft_type);

Footer3();

dbDisconnect($dbh);
