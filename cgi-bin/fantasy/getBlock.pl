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
<TITLE>Trading Block</TITLE>
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
  my $nav = Nav_Bar->new('Trade Block',"$user",$is_commish,$draftStatus,"$team_t");
  $nav->print();
}

####################
#
# Footer Print
#
####################

sub Footer()
{
print <<FOOTER;

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
    my $playerID = shift;
    my $name = shift;
    my $owner = shift;
    my $askingPrice = shift;

    my $getCost = $dbh->prepare("SELECT price FROM final_rosters WHERE name = '$playerID' AND league = '$league_name'");
    $getCost->execute();
    my $cost = $getCost->fetchrow();    
    $getCost->finish();

print <<PLAYERBOX;
  <tr>
    <td>$name</td>
    <td>$owner</td>
    <td>$cost</td>
    <td>$askingPrice</td>
  </tr>
PLAYERBOX

}

##########################################
#
#      Main Function
#
##########################################

## Get some queries ready
# List of players at a position
my $getBlockPlayers = $dbh->prepare("SELECT b.player,p.name,b.owner,b.askingprice FROM players p, trading_block b WHERE p.playerid=b.player and b.league='$league_t' ORDER BY b.owner");
my $getRosterPlayers = $dbh->prepare("SELECT f.name, p.name,f.price from final_rosters f, players p where f.name=p.playerid and f.league='$league_t' and f.team='$team_t'");

Header();
PrintNav();

print <<STUFF;
<div class='listContainer'>
<form name='addPlayer' action='putBlock.pl' method='POST'>
<table>
  <tr>
   <td colspan=4><b><i>$team_t</i> Roster Options</b></td>
  </tr>
  <tr>
   <td>?</td>
   <td>Player</td>
   <td>Cost</td>
   <td>Target</td>
  </tr>
STUFF

$getRosterPlayers->execute();
while (my ($id, $name, $price) = $getRosterPlayers->fetchrow_array())
{
print <<STUFF;
  <tr>
   <td><input type="checkbox" name="select_$id" value="add"/></td>
   <td>$name</td>
   <td>$price</td>
   <td>Target <input type="text" size="3" name="target_$id"></td>
  </tr>
STUFF
}

print "</table>\n";
print "<center><input type='submit' value='Add To Trading Block'>\n";
print "</form>\n";
print "</div>\n";

print <<TABLE;
  <div class='listContainer'>
  <table>
    <tr>
      <td><b>Player</b></td>
      <td><b>Team</b></td>
      <td><b>Current Cost</b></td>
      <td><b>Asking Price</b></td>
    </tr>
TABLE

# Main Block
$getBlockPlayers->execute();
while (my @row = $getBlockPlayers->fetchrow_array())
{
    PrintPlayer(@row);
}

print "</table></div><br>\n";

## End File
Footer();

$dbh->disconnect();
