#!/usr/bin/perl

use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use Session;
use DBTools;

# script to generate an auction page

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
<TITLE>Team Entry Page</TITLE>

<script language="JavaScript">
<!--
function pswd_checker()
{
  if (entry_form.TEAM_PASSWORD.value == '')
  {
    alert("Please enter a password")
    return (false);
  }

  if (entry_form.TEAMS.value == 'Select Your Team')
  {
    alert("Please select a Team")
    return (false);
  }

  return (true);
}
-->
</script>

<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<h2 align=center><u>Team Page</u></h2>

<br><br>
<p align=center>Click to see the <A href="/fantasy/rules.htm" target="rules">rules</a>.
<br><br>

<form name="entry_form" action="/cgi-bin/fantasy/checkPSWD.pl" method="post" onsubmit="return pswd_checker()">


HEADER

}

####################
#
# Footer1 Print
#
####################

sub Footer1()
{

print <<FOOTER1;

<p align=center>
<a name="BIDDING"><b>Sign In:</b></a>
<table frame="box" border=3>
  <tr>
    <td align=middle>Your Team Name</td>
    <td align=middle>Your Team Password</td>
  </tr>
    <tr>
      <td align=middle>
        <select name="TEAMS">

FOOTER1

}

####################
#
# Footer2 Print
#
####################

sub Footer2()
{

$userAddr = $ENV{REMOTE_ADDR};

print <<FOOTER2;

        </select>
      </td>
      <td align=middle>
        <input type="password" name="TEAM_PASSWORD">
      </td>
    </tr>
</table>

<br>

<input type="reset" value="Clear The Forms" id=reset1 name=reset1> 
<input type="submit" value="Enter!" id=submit1 name=submit1>
<br><br>
If you don't have a team, you can register one <a href="../../fantasy/register.html">here</a>.<br><br>
<b>Note:</b> For security purposes, if your session is inactive (ie. you do not change pages, make bids, etc.)<br>for more than $login_extend_time minutes, you will be prompted to sign in again.<br>This allows the system to confirm your team indentity for transactions.
<br><br>
Also, Please remember to <b>log out</b> of the system when finished - it makes it easier for us.
</form>
</p>    

</BODY>
</HTML>

FOOTER2

}

######################
#
# Print Owner
#
######################


sub PrintOwner($$)
{
my $owner = shift;
my $check = shift;

print <<EOM;

  <option value="$owner" $check>$owner</option>

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

<center>
$message<br>
</center>

EOM

}


##############
#
# Main Function
#
##############

# variables for players
my $name;
my $pos;
my $bid;
my $bidder;
my $time;
my $team;
my $count = 0;
my $owner;
my $password;
my $ez_time;

$set = 0;
$userAddr = $ENV{REMOTE_ADDR};

#get existing session
my $query = new CGI;
my $cookie = "SESS_ID";
my $id = $query->cookie(-name => "$cookie");
my $ip = "";
$dbh = dbConnect();

###################
#
# If logged in
#
###################

if($id){
  $sth = $dbh->prepare("SELECT owner, IP FROM sessions WHERE sess_id = '$id'")
        or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
   ($user,$ip) = $sth->fetchrow_array();
  $sth->finish();
}

if($ip eq $ENV{REMOTE_ADDR})
{

  print "Status: 302 Moved\nLocation: /fantasy/fantasy_main_index.htm\n\n";

}

else
{

  $sth = $dbh->prepare("SELECT owner FROM sessions WHERE ip = '$ENV{REMOTE_ADDR}'")
        or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
   $user = $sth->fetchrow();
  $sth->finish();

  $def = (defined $user) ? $user : "Select Your Team";
  Header();

  Footer1();

  PrintOwner("Select Your Team","");
  ## Connect to password database
  my $sth_names = $dbh->prepare("SELECT name FROM passwd");
#  my $sth_names = $dbh->prepare("SELECT name from players");
  $sth_names->execute();
  while ($owner = $sth_names->fetchrow())
  {
  
print "OWNER: $owner<br>";
    if ($owner eq $def)
    {
      $check = "selected";
    }
    else
    {
      $check = "";
    }
    PrintOwner($owner,$check);
  }
  $sth_names->finish();

  dbDisconnect($dbh);

  Footer2();

}
