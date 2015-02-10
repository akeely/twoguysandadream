#!/usr/bin/perl

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use Nav_Bar;
use DBTools;
use Session;

# script to generate team's home page (pre-draft)

# files
$log = "./getTargets_log.txt";

my ($my_ip,$user,$pswd,$my_id,$team_t,$sport_t,$league_t) = checkSession();
my $dbh = dbConnect();

#Get League Data
$sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($league_name,$password,$league_owner,$league_draftType,$draftStatus,$contractStatus,$sport,$categories,$league_positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
$sth->finish();

my @positions;
if($sport eq 'baseball')
{ 
    @positions = qw(C 1B 2B SS 3B OF SP RP DH);
}
else
{
    @positions = qw(QB RB WR TE K DEF);
}

my $query = new CGI;
my $limit = 'LIMIT 25';
$limit = '' if($query->param('limit') eq 'no');

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
<TITLE>Set Target Prices</TITLE>
</HEAD>
<BODY>
<p align="center">

HEADER

}

########################
#
# NavBar Print
#
########################

sub PrintNav()
{
  my $is_commish = ($league_owner eq $user) ? 1 : 0;
  my $nav = Nav_Bar->new('Set Targets',"$user",$is_commish,$draftStatus,"$team_t");
  $nav->print();
}

######################
#
# Print Owner
#
######################

sub PrintOwner($$)
{
  my $owner = shift;
  my $team = shift;

print <<EOM;
  <option value="$team"> 
  $team
EOM

}


####################
#
# Footer Print
#
####################

sub Footer()
{
print <<FOOTER;

</form>
</BODY>
</HTML>

FOOTER

}

######################
#
# Print Player
#
######################


sub PrintPlayer
{
    my $name = shift;
    my $playerID = shift;

    my $getTarget = $dbh->prepare("SELECT price FROM targets WHERE owner = '$user' AND playerID = '$playerID' AND league = '$league_name'");
    $getTarget->execute();
    my ($price) = $getTarget->fetchrow_array();    

print <<PLAYERBOX;
    <div class='listItem'>
        <div class='alignLeft'>$name</div>
        <div class='alignRight'>\$<input class='priceInput' name='$playerID' value='$price' /></div>    
    </div>

PLAYERBOX

}

##########################################
#
#      Main Function
#
##########################################

## Get some queries ready
# List of players at a position
my $getPlayers = $dbh->prepare("SELECT name, playerID FROM players WHERE position = ? ORDER BY rank $limit");

Header();
PrintNav();

print "</div>\n</p>\n";
print "<form name='getTargets' action='addTargets.pl' method='POST'>\n\n";
print "<input type='hidden' name='owner' value='$user'>\n";
print "<br>\n";
print "<center><input type='submit' value='Save Targets'>\n";
print "<a href='getTargets.pl?limit=no'>More Players >></a>\n</center>";
print "<div class='widePage'>\n";

# Main Block
foreach my $thisPosition (@positions)
{
    print "<div class='listContainer'>\n";
    print "    <div class='listHeading'>$thisPosition</div>\n";

    $getPlayers->execute($thisPosition);
    while (my @row = $getPlayers->fetchrow_array())
    {
        PrintPlayer(@row);
    }

    print "</div>\n";

}

print "</div>\n</form><br>\n";

## End File
Footer();

$dbh->disconnect();
