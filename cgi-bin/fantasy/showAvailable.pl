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
my $select_limit = ($query->param('select_limit') eq 'no') ? '' : $query->param('select_limit') || 100;
my $show_limit = ($query->param('show_limit') eq 'no') ? '' : $query->param('show_limit') || 25;

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
<TITLE>View Players</TITLE>

<script language="JavaScript">
<!--
  
  var show = 'all'
  var limits_array = new Array()

HEADER

  foreach my $pos (@positions)
  {
    print "  limits_array['$pos'] = $show_limit\n";
  }

print <<HEADER;

  function show_players (position, amount)
  {
    var cap = 999
    if (amount != "ALL")
    {
      cap = document.getElementById(position + "_amount").value
    }

    limits_array[position] = cap
    div = document.getElementById(position);
 
    var count = 0
    var elms = div.getElementsByTagName("div")
    for(var i = 0, maxI = elms.length; i < maxI; ++i) {
     var elm = elms[i]

     var divclass = elm.getAttribute("class")
     if (divclass != "listItem") { continue }

     if (count < cap)
     {
       var title = elm.getAttribute("title")
       if (show == 'all' || title != 'sold')
       {
         elm.style.display = "block"
         count++;
       }
       else
       {
         elm.style.display = "none"
       }
     }
     else
     {
       elm.style.display = "none"
     }

    }
  }

  function toggle_view ()
  {
    if (show == 'all') {show = 'new'}
    else {show = 'all'}

    for (var i in limits_array)
    {
      var limit = limits_array[i]
      if (limit == 999) {limit = 'ALL'}

      show_players(i,limit)
    }

//    var this_limit = 0
//    var count = 0
//    table = document.getElementById("fulltable")
//    var elms = table.getElementsByTagName("div")
//    for(var i = 0, maxI = elms.length; i < maxI; ++i) {
//     var elm = elms[i]
//
//     var divclass = elm.getAttribute("class")
//    
//     // reset the display limit & count for each position column
//     if (divclass == 'listContainer') 
//     {
//       pos = elm.id
//       this_limit = limits_array[pos]
//
//       count = 0
//     }
//
//     // Only count/act upon listItems (player boxes)
//     if (divclass != "listItem") { continue }
//
//     if (count >= this_limit)
//     {
//       elm.style.display = "none"
//       continue
//     }
//
//     var title = elm.getAttribute("title")
//     if (show == 'all' || title != 'sold')
//     {
//       elm.style.display = "block"
//       count++;
//     }
//     else
//     {
//       elm.style.display = "none"
//     }
//
//    }
     
  }

-->
</script>


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
    my $count = shift;

    my $getCost = $dbh->prepare("SELECT p.price, c.player,t.player FROM players_won p LEFT JOIN contracts c ON (c.league=p.league and c.player=p.name) LEFT JOIN tags t ON (t.league=p.league and t.player=p.name) WHERE p.name = '$playerID' AND p.league = '$league_name'");
    $getCost->execute();
    my ($price,$is_contract,$is_tag) = $getCost->fetchrow_array();

    
    my $style = ($count >= $show_limit) ? "style=\"DISPLAY: none\"" : "";
    my $keep_tag = '';
    if (defined $is_contract) { $keep_tag = "KPR"; }
    elsif (defined $is_tag) { $keep_tag = "TAG"; }
    $price = "$keep_tag  \$$price" if ($keep_tag !~ /^$/);
   
    my $title;
    $title = "title='sold'" if ($price !~ /^$/);

print <<PLAYERBOX;
    <div class='listItem' $title $style>
PLAYERBOX

print "    <b>\n" if (! defined $price);
print "    <i>\n" if ((defined $is_contract) || (defined $is_tag));

print <<PLAYERBOX;
        <div class='alignLeft'>$name</div>
        <div class='alignRight'>$price</div>    
PLAYERBOX

print "    </b>\n" if (! defined $price);
print "    </i>\n" if ((defined $is_contract) || (defined $is_tag));

print <<PLAYERBOX;
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
my $limit_clause = ((defined $select_limit) && ($select_limit !~ /^$/)) ? "LIMIT $select_limit" : "";
my $getPlayers = $dbh->prepare("SELECT name, playerID FROM players WHERE position = ?  and active=1 ORDER BY rank $limit_clause");

Header();
PrintNav();

my $main_divtype = 'widePage' . uc(substr($sport_t,0,1));
print "</div>\n</p>\n";
print "<br>\n";
print "<a href='javascript:toggle_view()'>Hide/Show Purchased Players</a>\n<br><br>";
print "<div class='$main_divtype' id='fulltable'>\n";

# Main Block
foreach my $thisPosition (@positions)
{
    my $count = 0;

print <<TOP;
<div class='listContainer' id='$thisPosition'>
   <div class='listHeading'>$thisPosition</div>
   <div class='listWidget'>
     Show:
     <a href="javascript:show_players('$thisPosition','ALL')">ALL</a><br>or<br>
     <input type="text" id="${thisPosition}_amount" value="$show_limit" size=1 maxlength=3>
     <a href="javascript:show_players('$thisPosition','CHECK')">SOME</a><br>
   </div>
TOP

    $getPlayers->execute($thisPosition);
    while (my @row = $getPlayers->fetchrow_array())
    {
        PrintPlayer(@row,$count++);
    }

    print "</div>\n";

}

print "</div>\n</form><br>\n";

## End File
Footer();

$dbh->disconnect();
