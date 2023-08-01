#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use DBTools;
use Session;

my $cgi = new CGI;

# script to generate a pull-down selection for owner's teams/leagues

# files
$team_error_file = "/var/log/fantasy/team_errors.txt";
$drafting_color = "#54C571";
$keeping_color = "#FBB117";
$stagnant_color = "#F75D59";

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
</HEAD>
<BODY>

<p align=center>Visit your team clubhouse(s):<br>
<table>
 <tr>
  <td STYLE='background-color: $drafting_color'>Leagues Drafting </td>
  <td> | </td>
  <td STYLE='background-color: $keeping_color'>Leagues With Keepers Open </td>
  <td> | </td>
  <td STYLE='background-color: $stagnant_color'>Stagnant Leagues</td>
 </tr>
</table>

<form action="/cgi-bin/fantasy/putTeam.pl" method="post" target="_top">

<table align=center>
 <tr>
  <td rowspan=2>
   <select name="user_sport">


HEADER

}

####################
#
# Footer2 Print
#
####################

sub Footer2()
{

print <<FOOTER2;

</select>
  </td>
  <td>
   <input type="submit" value="Go!">  
  </td>
 </tr>
</table>
</form>
</p>    

</BODY>
</HTML>

FOOTER2

}


##############
#
# Main Function
#
##############


# variables for players

$userAddr = $ENV{REMOTE_ADDR};
$set = 0;
$num = "5";
$namer = "a";
$pswd = "p";
$time = "1:1:1";

my ($ip, $sess_id, $sport_t, $league_t, $team_t, $ownerid)  = checkSession();
my $dbh = dbConnect();
  open(TEAM,">$team_error_file");
  flock(TEAM,2);
  print TEAM "$ip, $sess_id, $sport_t, $league_t, $team_t, $ownerid";
  close(TEAM);

# If the session is from a different IP, force the user to sign in
if ((!$id) | ($ENV{HTTP_REFERER} ne "/fantasy/fantasy_main_index.htm"))
{
  open(TEAM,">$team_error_file");
  flock(TEAM,2);
  print TEAM "<b>You must login!</b>\n";
  close(TEAM);

  dbDisconnect($dbh);


  print "Cache-Control: no-cache\n";
  print "Content-type: text/html\n\n";

print <<EOF;

<HTML>
<HEAD>
<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>

<p align=center>
<br>
<a href="/cgi-bin/fantasy/logout.pl" target="_top">Please LOGIN, you cannot use any functionality on this site without a user name!</a>

</p>    

</BODY>
</HTML>

EOF

  exit;
}

else
{

  Header();

  ## Get any teams currently drafting
  $sth = $dbh->prepare("SELECT t.id, t.name, t.leagueid, t.sport FROM teams t, leagues l WHERE t.ownerid = '$ownerid' and l.draft_status in ('open','paused') and t.leagueid=l.id")
       or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();

  $teams_count = 0;
  while (($tf_id, $tf_name, $tf_league, $tf_sport) = $sth->fetchrow_array())
  {
    print "<option value='$tf_id:$tf_sport:$tf_league' STYLE='background-color: $drafting_color'>$tf_name - $tf_league</option>";
    $teams_count++;
  }
  $sth->finish();

  ## Get any teams that can select keepers
  $sth = $dbh->prepare("SELECT t.id, t.name, t.leagueid, t.sport FROM teams t, leagues l WHERE t.ownerid = '$ownerid' and l.keepers_locked='no' and l.draft_status='closed' and t.leagueid=l.id")
       or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();

  $teams_count = 0;
  while ($tf_id, ($tf_name, $tf_league, $tf_sport) = $sth->fetchrow_array())
  {  
    print "<option value='$tf_id:$tf_sport:$tf_league' STYLE='background-color: $keeping_color'>$tf_name - $tf_league</option>";
    $teams_count++;
  }
  $sth->finish();

  ## Get any remaining (dormant) teams
  $sth = $dbh->prepare("SELECT t.id, t.name, t.leagueid, t.sport FROM teams t, leagues l WHERE t.ownerid = '$ownerid' and l.keepers_locked='yes' and l.draft_status='closed' and t.leagueid=l.id order by l.id desc")
       or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();

  $teams_count = 0;
  while (($tf_id, $tf_name, $tf_league, $tf_sport) = $sth->fetchrow_array())
  {  
    print "<option value='$tf_id:$tf_sport:$tf_league' STYLE='background-color: $stagnant_color'>$tf_name - $tf_league</option>";
    $teams_count++;
  }
  $sth->finish();
  dbDisconnect($dbh);

  if ($teams_count == 0)
  {
    print '<option value=no_team>No Teams Available</option>';
  }

  Footer2();
}
