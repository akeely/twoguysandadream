#!/usr/bin/perl

BEGIN
{
  push(@INC, '/home/gunsli5/public_html/cgi-bin/fantasy');
}
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Nav_Bar;
use Leagues;
use POSIX qw(ceil floor);
use DBTools;
use Session;

my $cgi = new CGI;

$log = "./getContracts_LOG.txt";
$errorflag = 0;


## Set up FA/Waiver player values
my %pos_costs;
my $total_num = 0;
my $total_contract_types = 0;
my $contract_types_string = '';
my %keeper_slots;

## 'expired/expiring' tag depending on draft status
my $exp_text = 'EXPIRED';

########################
#
# Header Print
#
########################

sub Header($$$$$)
{
my $global_lock = shift;
my $head_user = shift;
my $head_team = shift;
my $league_owner = shift;
my $draft_status = shift;

print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";

print <<HEADER;

<HTML>
<HEAD>
<TITLE>League Contracts Page</TITLE>
<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<p align=center>

HEADER

  my $is_commish = ($league_owner eq $head_user) ? 1 : 0;
  my $nav = Nav_Bar->new('LContracts',"$head_user",$is_commish,$draft_status,"$head_team");
  $nav->print();
  
print <<HEADER;

<center>
<br><br>

<b>LEAGUE KEEPER CONTRACTS</b><br><br>

These are the current / expired contracts for your league. As owners update their keepers, this list will reflect any additions.
<br><br>
Sorry for the terrible display scheme. A quick description:
<br><b><font color="black">Black:</font></b> Players currently under contract (previous seasons, and those locked for this year)
<br><font color="blue">Blue:</font> Player whose contracts have expired. These players may become RFAs, if supported in your league charter
<br><b><font color="red">Red:</font></b> Players whose contracts have been broken by the owner - the owner incurs a penalty (shown under 'Future Cost(s)')

  <div class="center">
<br>
<table frame=box cellpadding=6 bordercolor=#666666 border=3 rules=all style="margin-left: auto; margin-right: auto; text-align: center;">
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

</p>
</BODY>
</HTML>

FOOTER

}



######################
#
# Print Owner
#
######################



sub PrintOwner($$$)
{
my $owner = shift;
my $team = shift;
my $check = shift;

print <<EOM;

  <option value="$owner" $check> 
  $team
  </option>

EOM

}


######################
#
# Print Player
#
######################

sub PrintPlayer($$$$$$$$$)
{
my $team = shift;
my $orig_team = shift;
my $name = shift;
my $cost = shift;
my $years_left = shift;
my $pos = shift;
my $broken = shift;
my $penalty = shift;
my $type = shift;

my $style = '';
my $start_year = 0;
my @costs = ();
my $cost2;
my $last_cost = $cost; ## Overwritten if FA/Waiver player

## If the player's price is listed as 0, he was a FA pickup. Assign him the initial price
## for his position, stored in the hash
if ($cost == 0)
{
  $pos = $1 if ($pos =~ m/(.*)\|.*/);
  $last_cost = $pos_costs{uc($pos)};

  ## Error flagging
  $last_cost = -1 if (! defined $last_cost); 

  $start_year = 1;
  push(@costs, $last_cost);
}

  my $cost_calcs = 1;
  if ($years_left ne 'N/A')
  {
    $cost_calcs = $years_left;
  }

  ## If $0.50 bidding is available (i.e. cost is under 10 dollars), round to nearest 50 cents
  for (my $x=$start_year; $x<$cost_calcs; $x++)
  {
    $temp_cost = $last_cost * $keeper_increase;
    if ($temp_cost < 10)
    {
      ($main, $dec) = split(/\./,$temp_cost);
      my $dec2 = substr($dec, 0, 1);
      $cost2 = ceil($temp_cost);
      if (($dec2 <= 5) && (($dec2 > 0) || (($dec2 == 0) && (length($dec) == 2))))
      {
        $cost2 = $main . '.5';
        ## For the $0.50 players, need to make sure they are bumped up
        if ($cost2 == $last_cost)
        {
          $cost2 += 0.5;
        }
      }
    }
    else
    {
      $cost2 = ceil($temp_cost);
    }
    push(@costs, $cost2);
    $last_cost = $cost2;
  }

$cost2 = join(' | ',@costs);
$cost2 = '' if ($team =~ /^$/);


## Account for the '-1' tag for expired contracts
if ($years_left == -1)
{
  $cost2 = 'N/A';
  $years_left = $exp_text;
  
  $style = "color: grey";
}


## Add some designation for Franchise / Transition
$years_left .= "  ($type TAG)" if ($type !~ /^$/);


## Account for broken contracts
if (($broken eq 'Y') || (($team eq 'NONE') && ($years_left > 0)))
{
  $cost2 = $penalty;
  $years_left .= ' - BROKEN';
  
  $style = "color: red; font-weight:bold";
}

$style = "font-weight:bold" if ($style =~ /^$/);
$style .= "; font-size: 85\%";
$style = "style= \"$style\"";

print <<EOM;
 <tr $style>
  <td id="origTeam">$o_tag $team $c_tag</td>
  <td id="teamName">$o_tag $orig_team $c_tag</td>
  <td id="player_name">$o_tag $name $c_tag</td>
  <td id=cost align=center>$o_tag $cost $c_tag</td>
  <td id=next_cost align=center>$o_tag $cost2 $c_tag</td>
  <td id=years_left align=center>$o_tag $years_left $c_tag</td>
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

 
## Get keeper prices for free-agent pickups (varies by league)
my @fa_positions;
@fa_positions = ('QB','RB','WR','TE','K','DEF') if ($sport eq 'football');
@fa_positions = ('C','1B','2B','3B','SS','OF','DH','SP','RP') if ($sport eq 'baseball');
foreach my $pos (@fa_positions)
{
  $pos_costs{$pos}  = $league->keeper_fa_price($pos);
}

Header($contractStatus,$user,$team_t,$owner,$draftStatus);


print <<EOM;

  <table frame=box class=none id=contracts>
   <tr>
    <td colspan=6 align=center class=none>
     <b>$league_t</b>
    </td>
   </tr>
   <tr>
    <td>
     <b>Current Team</b>
    </td>
    <td>
     <b>Original Team</b>
    </td>
    <td>
     <b>Player Name</b>
    </td>
    <td>
     <b>Current Cost</b>
    </td>
    <td>
     <b>Future Cost(s)</b>
    </td>
    <td>
     <b>Years Left on Contract</b>
    </td>
   </tr>

EOM

##  $sth = $dbh->prepare("SELECT w.name,w.price,w.team,w.time,p.position,p.name FROM final_rosters w, players p WHERE w.league='$league_t' and w.name=p.playerid")
##           or die "Cannot prepare: " . $dbh->errstr();
##  $sth->execute() or die "Cannot execute: " . $sth->errstr();
##  $sth2 = $dbh->prepare("SELECT current_cost,total_years,years_left,team,locked from contracts where player=? and league='$league_t'");
  
my $sth;
if ($draftStatus eq 'open')
{
  $sth = $dbh->prepare("SELECT t.name, w.team, p.name, w.price, c.years_left, p.position, c.type, c.broken, c.penalty from players_won w, players p, contracts c, teams t where w.league='$league_t' and w.name=p.playerid and c.player=w.name and c.league=w.league and c.team=t.owner and t.league=w.league and c.locked='yes' order by w.team, c.years_left");
  $exp_text = 'EXPIRING';
}
else
{
  $sth = $dbh->prepare("SELECT t.name, w.team, p.name, w.price, c.years_left, p.position, c.type, c.broken, c.penalty from final_rosters w, players p, contracts c, teams t where w.league='$league_t' and w.name=p.playerid and c.player=w.name and c.league=w.league and c.team=t.owner and t.league=w.league and c.locked='yes' order by w.team, c.years_left");
  $exp_text = 'EXPIRED';
}

my $last_team = '';
my $player_years_left;
$sth->execute();
while (($orig_bidder,$bidder,$name,$bid,$player_years_left,$pos,$type,$broken,$penalty) = $sth->fetchrow_array())
{ 
##    next if ($bidder eq 'NONE');
  $type = '' if ($type =~ /\d/);
  PrintPlayer ('','','','','','','','','') if (($last_team ne $bidder) && ($last_team !~ /^$/));
  PrintPlayer($bidder,$orig_bidder,$name,$bid,$player_years_left,$pos,$broken,$penalty,$type);
  $last_team = $bidder;
}   
$sth->finish();

print <<EOM;

</table>
</center>
</div>
</form>

EOM

Footer();


sub by_type_index {
  my $index1 = $keeper_slots{$a}->{INDEX};
  my $index2 = $keeper_slots{$b}->{INDEX};

  $index1 <=> $index2;
}
