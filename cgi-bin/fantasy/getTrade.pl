#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use DBTools;
use Session;

my $cgi = new CGI;

$errorflag = 0;

## Input variables
my $other_team = $cgi->param('TEAMS');

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
<TITLE>Propose a Trade</TITLE>
<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<p align=center>
<center>

<b>Select the players that you would like to be involved in the trade:</b><br><br>

<form action="/cgi-bin/fantasy/proposeTrade.pl" method="post">
<table frame=box cellpadding=6 bordercolor=#666666 border=3 rules=all>
<tr>
 <td valign=top>

HEADER

}

########################
#
# Footer Print
#
########################

sub Footer()
{
print <<FOOTER;

</center>
</p>
</BODY>
</HTML>

FOOTER

}

######################
#
# Print Player
#
######################


sub PrintPlayer($$$$$)
{
  my $name = shift;
  my $id   = shift;
  my $count = shift;
  my $type = shift;
  my $cost = shift;

print <<EOM;

 <tr>
  <td><input type=checkbox name="$type$count" value="$id">
      <input type=hidden name="cost$type$count" value="$cost">
  </td>
  <td>$name</td>
  <td>$cost</td>
 </tr>

EOM

}


##############
#
# Main Function
#
##############

my $name;


############################################
######################
##
## Get Team ID, etc.
##
######################
############################################

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) = checkSession();
my $dbh = dbConnect();

  #Get League Data
  $sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  ($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
  $sth->finish();

  Header();

print <<EOM;
  
  <table frame=box class=none>
   <tr>
    <td colspan=3 align=center class=none>
     <b>$team_t</b>
    </td>
   </tr>

EOM

  $count = 0;
  $sth_trade = $dbh->prepare("SELECT p.name, w.price, p.playerid FROM players_won w, players p WHERE w.team=? AND w.league='$league_t' AND w.name=p.playerid")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth_trade->execute($team_t) or die "Cannot execute: " . $sth_trade->errstr();

  while (($name,$bid,$id) = $sth_trade->fetchrow_array())
  {
    PrintPlayer($name,$id,$count,'out',$bid);
    $count++;
  }   
  $sth_trade->finish();

print <<EOM;

  <input type=hidden name=count_out value=$count>
  </table>
 </td>
 <td valign=top>
  <table class=none frame=box>
   <tr>
    <td colspan=3 align=center class=none>
     <b>$other_team</b>
    </td>
   </tr>

EOM

  $count = 0;
  $sth_trade->execute($other_team) or die "Cannot execute: " . $sth->errstr();
  while (($name,$bid,$id) = $sth_trade->fetchrow_array())
  {
       PrintPlayer($name,$id,$count,'in',$bid);
       $count++;
  }   
  $sth_trade->finish();
  dbDisconnect($dbh);

print <<EOM;

  <input type=hidden name=count_in value=$count>
  </table>
 </td>
</tr>
</table>
<br>
<input type=hidden name=proposer value="$team_t">
<input type=hidden name=receiver value="$other_team">
<input type=submit value="Propose Trade">
</form>

EOM

  Footer();
