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
$keeper_text = "Lock These Keeper Choices!";
$errorflag = 0;


## Set up FA/Waiver player values
my %pos_costs;
my $total_num = 0;
my $total_contract_types = 0;
my $contract_types_string = '';
my %keeper_slots;
##my @colors = ('#347235','#F87431','#ECD872'); ## ECW - will need more of these ...
my @colors = ('#99FF99','#F87431','#ECD872'); ## ECW - will need more of these ...

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
<TITLE>Player Contracts Page</TITLE>

<script language="JavaScript">
<!--
function createRequestObject()
{
    var ro;
    try
    {
        // Firefox, Opera 8.0+, Safari
        ro = new XMLHttpRequest();
    }
    catch (e)
    {
       // Internet Explorer
       try
       {
          ro = new ActiveXObject("Msxml2.XMLHTTP");
       }
       catch (e)
       {
          try
          {
             ro = new ActiveXObject("Microsoft.XMLHTTP");
          }
          catch (e)
          {
             alert("ERROR: Your browser does not support AJAX!");
             return false;
          }
       }
    }
    return ro;
}
-->
</script>


<script language="JavaScript">
<!--
  var http = createRequestObject()
  var nums = new Array()
  var mins = new Array()
  var maxs = new Array()
  var colors = new Array()
  var select_indexs = new Array()
  var contract_types_string
  var types = new Array()
-->
</script>

<script language="JavaScript">
<!--
function sndReq() 
{
    var sendme=contract_form.TEAMS.options[contract_form.TEAMS.selectedIndex].value+";"+my_league;
    contract_form.TEAMS.disabled = true;
    contract_form.submit_contract.disabled = true;
    http.open('GET','getReqRoster.pl?action='+sendme)
    http.onreadystatechange = printRoster
    http.send(null)
}
-->
</script>


<script language="JavaScript">
<!--
function snd_check_contracts()
{
    var sendme = team+";"+contract_form.league.value;
    http.open('GET','/cgi-bin/fantasy/checkUserContracts.pl?action='+sendme)
    http.onreadystatechange = check_contracts
    http.send(null)
}
-->
</script>


<script language="JavaScript">
<!--
function snd_check_contracts_no_args()
{
    if (contract_form.ip_flag.value == 'yes')
    {
      var sendme = contract_form.TEAMS.value + ";" + contract_form.league.value;
    }
    else
    {
      var sendme = contract_form.TEAMS.options[contract_form.TEAMS.selectedIndex].value + ";" + contract_form.league.value;
    }
    
    http.open('GET','/cgi-bin/fantasy/checkUserContracts.pl?action='+sendme)
    http.onreadystatechange = check_contracts
    http.send(null)
}
-->
</script>


<script language="JavaScript">
<!--
function pswd_checker()
{
  if (contract_form.ip_flag.value != 'yes')
  {
    if (contract_form.TEAM_PASSWORD.value == '')
    {
      alert("Please enter a password")
      return (false);
    }

    if (contract_form.TEAMS.value == 'Select A Team')
    {
      alert("Please select a Team")
      return (false)
    }
  }

  return(table_update(1))
}
-->
</script>


<script language="JavaScript">
<!--
function table_update(submitted)
{
  var contract_count = 0
  var total_contracts = $total_num
  var counts = new Array();

  for (var check_type in types)
  {
    check_type_val = types[check_type]
    counts[check_type_val] = 0
  }

  for (var i = 1; i < (contracts.rows.length - 1); i++)
  { 
    var text = "contract_form.Contract" + (i - 1) + ".selectedIndex";
    var text_val = eval(text)

    text = "contract_form.Year" + (i-1)
    var year_select = eval(text)

    text = "contract_form.Contract" + (i-1)
    var contract_select = eval(text)

    // For non-contracted players/selections
    if ((text_val  == 0) || (text_val  == 4))
    {
      for (var p = year_select.length; p > 0; p--)
      {
        year_select.options[p-1] = null
      }
      contracts.rows[i + 1].style.backgroundColor ="#EEEEEE"
      continue;
    }
    
    contract_count++;
    if (contract_count > total_contracts)
    {
      alert("You can only give contracts to " + total_contracts + " players!")
      return(false)
    }

    var current_year = year_select.selectedIndex;
    if (current_year < 1)
      current_year = 0;
    
    for (var check_type in types)
    {
      check_type_val = types[check_type]
      if (text_val == (parseInt(check_type)+1))
      {
        if (counts[check_type_val] < nums[check_type_val])
        {
          for (var p = mins[check_type_val]; p < (maxs[check_type_val] + 1); p++)
          {
            year_select.options[p-1] = new Option(p,p);
          }
          for (var p = year_select.length; p > (maxs[check_type_val]); p--)
          {
            year_select.options[p-1] = null
          }
          contracts.rows[i + 1].style.backgroundColor = colors[check_type_val]
          year_select.selectedIndex = current_year;
          counts[check_type_val]++;
        }
        else
        {
           contract_count--;
           alert("You can only assign " + nums[check_type_val] + " '" + check_type_val + "' contract(s)!")
           return(false)
           continue
        }
      }
    }
  } // end for-loop (i))

  if ((contract_form.LOCK_ME.checked) && (submitted == 1))
  {
    var answer = confirm("This will LOCK these keepers for this offseason. You can lock up to " + total_contracts + " keepers. Continue?")
    if (answer)
    {
      return(true);
    }
    return(false);
  } // end if ((contract_form.LOCK_ME.checked) && (submitted == 1))

  return(true)
} // end table_update

-->
</script>


<script language="JavaScript">
<!--
function check_contracts() 
{
  if(http.readyState == 4)
  {

    var response = http.responseText
    var keeper_terms = new Array()
    var update = new Array()
    var players = new Array()
    var table_size = (contracts.rows.length - 2);
    var global_lock = contract_form.global_lock.value;
    var total_contracts = $total_num
    var counts = new Array();
    contract_types_string = "$contract_types_string"
    types = contract_types_string.split('|')
    for (var check_type in types)
    {
      check_type_val = types[check_type]
      counts[check_type_val] = 0
    }

    // Explicit declaration for perl hash vars that we are importing here. Yes, very graceful, thanks for noticing
HEADER
  

## Set up some tricky passing of hash data - can we find the JSON module anywhere?
  foreach my $letter (sort keys % keeper_slots)
  {
     print "    nums[\"$letter\"] = $keeper_slots{$letter}->{NUMBER}\n";
     print "    mins[\"$letter\"] = $keeper_slots{$letter}->{MIN}\n";
     print "    maxs[\"$letter\"] = $keeper_slots{$letter}->{MAX}\n";
     print "    colors[\"$letter\"] = '$keeper_slots{$letter}->{COLOR}'\n";
     print "    select_indexs[\"$letter\"] = '$keeper_slots{$letter}->{INDEX}'\n";
     print "\n";
  }


print <<HEADER;

    if(response.indexOf(';') != -1) 
    {
      update = response.split(';')
    }

    for (var i = 0; i < (update.length); i++)
    {
      players[i] = update[i].split(',')
    }

    var player_length = (players.length-1);
    var row_count =1;
    var num_locked = 0;
    for (var i = 1; i <= (table_size); i++)
    {
      for (var j = 0; j<player_length; j++)
      {
        var text = "contract_form.idout" + (i-1) + ".value"
        var id = eval(text)

        // If the player has been assigned a contract
        if (id == players[j][0])
        {
          text = "contract_form.Contract" + (i-1)
          var contract_select = eval(text)
          text = "contract_form.Year" + (i-1)
          var year_select = eval(text)

          // Franchise/Transition Players
          if ((players[j][1] == 'F') || (players[j][1] == 'T'))
          {
            if (players[j][1] == 'F')
            {
              contract_select.options[4] = new Option('Franchise');
              contract_select.selectedIndex = 4;
              contract_select.disabled = true;
              year_select.disabled = true;
            }
            if (players[j][1] == 'T')
            {
              contract_select.options[4] = new Option('Transition');
              contract_select.selectedIndex = 4;
              contract_select.disabled = true;
              year_select.disabled = true;
            }
            
            break;
          }

          // If years_left == -1, this is an expired contract - cannot be assigned again!
          if ((players[j][4] != -1) && (players[j][4] != -2))
          {

            // check the years_left, match it to its best 'contract type'
            var best_fit_index
            var best_fit_delta=99
            for (var lengths in maxs)
            {
              var check_me = (maxs[lengths] - players[j][4]);
  
              // if the contract type we checked is not long enough to handle this contract, SKIP
              if (check_me < 0)
              {
                continue;
              }

              if (check_me < best_fit_delta)
              {
                if (counts[lengths] < nums[lengths])
                {
                  best_fit_delta = check_me
                  best_fit_index = lengths
                }
              }
            }

            // update the counts for this contract type!
            counts[best_fit_index]++;

            contract_select.selectedIndex = select_indexs[best_fit_index]
 
            // Set appropriate colors
            contracts.rows[i + 1].style.backgroundColor = colors[best_fit_index]

            for (var p = 1; p < (maxs[best_fit_index] + 1); p++)
            {
              year_select.options[p-1] = new Option(p,p);
            }

            year_select.selectedIndex = (players[j][4] - 1);
          }

          // Disable forms if player already in contract
          if (players[j][3] == 1)
          {
            contract_select.disabled = true;
            year_select.disabled = true;
            if (players[j][4] > 0)
            {
              num_locked++;
            }
          }
          break
        } // end if (id == players[j][0])
      } // end for-loop (j)

      // Disable forms if player already in contract
      if (global_lock == 'yes')
      {
        text = "contract_form.Contract" + (i-1)
        var contract_select = eval(text)
        text = "contract_form.Year" + (i-1)
        var year_select = eval(text)

        contract_select.disabled = true;
        year_select.disabled = true;
      }

    } // end for-loop (i)
    
    if (num_locked == total_contracts)
    {
      contract_form.TEAMS.disabled = true;
      contract_form.submit_contract.disabled = true;
      contract_form.reset1.disabled = true;
      contract_form.LOCK_ME.disabled = true;
    }
  } // end if(http.readyState == 4)
} // end check_contracts
-->
</script>



<script language="JavaScript">
<!--
function printRoster()
{
 
  if(http.readyState == 4)
  {
    var response = http.responseText
    var update = new Array()
    var te = new Array()
    var players = new Array()
    var table_size = (contracts.rows.length - 2);
    var the_team = contract_form.TEAMS.options[contract_form.TEAMS.selectedIndex].text
    var total_contracts = $total_num

    if(response.indexOf(';') != -1) 
    {
      update = response.split(';')
    }

    temp = update[1].split(',')

    for (var i = 0; i < (temp.length); i++)
    {
      players[i] = temp[i].split(':')
    }

    contracts.rows[0].cells[0].innerHTML = "<b>" + contract_form.TEAMS.value + "</b>";

    var player_length = (players.length - 1);
    var row_count = 1;

    for (var i = 1; (i <= (table_size)) && (i <= player_length) ; i++)
    {
      var player_data = players[i][0].split('|');
      var text = "contract_form.costout" + (i - 1) + ".value = players[" + (i) + "][1]";
      eval(text)
      var text = "contract_form.idout" + (i - 1) + ".value = player_data[0]";
      eval(text)

      text = "player_name" + (i - 1) + ".innerHTML = player_data[1]";
      eval(text)

      text = "contract_form.Year" + (i - 1)
      var year_select = eval(text)
      year_select.disabled = false;

      text = "contract_form.Contract" + (i - 1)
      var contract_select = eval(text)
      contract_select.disabled = false;

      contract_select.selectedIndex = 0;
      contracts.rows[i+1].style.backgroundColor ="#EEEEEE"

      for (var p = year_select.length; p > 0; p--)
      {
        year_select.options[p-1] = null
      }

    }

    // If we have extra rows in the new table
    if ((table_size) > player_length)
    {
      for (var i = (table_size); i > player_length; i--)
      {
        // remove the bottom row
        contracts.rows[i+1].cells[1].innerHTML = "EMPTY";

        text = "contract_form.Year" + (i-1)
        var year_select = eval(text)
        year_select.disabled = true;

        text = "contract_form.Contract" + (i-1)
        var contract_select = eval(text)
        contract_select.disabled = true;
        contract_select.selectedIndex = 0;
        contracts.rows[i - 1].style.backgroundColor ="#EEEEEE"
        for (var p = year_select.length; p > 0; p--)
        {
          year_select.options[p-1] = null
        }

      }
    }

    snd_check_contracts();
    contract_form.TEAMS.disabled = false;
    contract_form.submit_contract.disabled = false;
    contract_form.total.value = player_length;
  }
}
-->
</script>

<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY onLoad="snd_check_contracts_no_args()">
<p align=center>

HEADER

  my $is_commish = ($league_owner eq $head_user) ? 1 : 0;
  my $nav = Nav_Bar->new('Contracts',"$head_user",$is_commish,$draft_status,"$head_team");
  $nav->print();

print <<HEADER;
<center>
<br><br>

<b>KEEPER CONTRACTS</b><br><br>
This page allows you to select contracts for your keeper league players.<br>
The contracts available are:<br>
HEADER


foreach my $contract_type (sort keys %keeper_slots)
{
  print "<font color=$keeper_slots{$contract_type}->{COLOR}>Type <b>$contract_type</b>: Maximum of $keeper_slots{$contract_type}->{MAX} years ($keeper_slots{$contract_type}->{NUMBER} contracts)</font><br>\n";
}

print "<br><br>\n";
print "<table frame=box cellpadding=6 bordercolor=#666666 border=3 rules=all style=\"margin-left: auto; margin-right: auto; text-align: center;\">\n<tr><td colspan=" . (keys %pos_costs) . "><b>Free Agent Salary Tiers</b></td></tr><tr>\n";

foreach my $fa_pos (sort keys %pos_costs)
{
  print "<td valign=top>$fa_pos</td>\n";
}
print "</tr><tr>\n";
foreach my $fa_pos (sort keys %pos_costs)
{
  print "<td valign=top>$pos_costs{$fa_pos}</td>\n";
}
print "</table>\n";




print <<HEADER;
<br><br>
You can have anywhere from zero to $total_num contracts in use at once - <br>
it is up to you the manager to decide what players should be signed for long terms deals.<br> Please be aware of the keeper contract <a href="/fantasy/rules.htm">rules</a> before making any decisions.
<br><b>When you are ready to finalize your keepers, check the '$keeper_text' box, and hit the Assign button</b>
HEADER


if ($global_lock eq 'yes')
{
  print"<br><br><h3> The Contract Assignment Period has ended. All contracts are now locked until next year. </h3> <br>\n";
}


print <<HEADER;

<form action="/cgi-bin/fantasy/putContracts1.pl" method="post" id=contract_form onSubmit="return pswd_checker()">
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


sub PrintPlayer($$$$$$$$$$)
{
my $name = shift;
my $id = shift;
my $count = shift;
my $type = shift;
my $cost = shift;
my $years_left = shift;
my $pos = shift;
my $c_owner=shift;
my $owner=shift;
my $is_broken=shift;


my $start_year = 0;
my @costs = ();
my $cost2;
my $last_cost = $cost; ## Overwritten if FA/Waiver player

## If the players price is listed as 0, he was a FA pickup. Assign him the initial price
## for his position, stored in the hash
if ($cost == 0)
{
  $pos = $1 if ($pos =~ m/(.*)\|.*/);
  $pos = $1 if ($pos =~ m/(.*)\/.*/);
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

  ## Account for contracts that were not made by this owner
##  if ($owner ne $c_owner)
##  {
##    
##    $years_left = 'N/A';
##    $cost_calcs = 1;
##  }

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

$cost2 = '';
foreach my $c (@costs)
{
  $cost2 .= $c . ' | ';
}
# Remove trailing ' | '
$cost2 = substr($cost2, 0, (length($cost2) - 3));

## Account for the '-1' tag for expired contracts
if ($years_left == -1)
{
  $cost2 = 'N/A';
  $years_left = 'EXPIRED';
}

## Account for the '-2' tag for broken contracts
if ($is_broken eq 'Y')
{
  $cost2 = 'N/A';
  $years_left .= '  (BROKEN)';
}


print <<EOM;
 <tr>
  <td>
        <SELECT NAME="Contract$count" onChange="table_update(0)">
        <OPTION SELECTED>NONE
EOM


foreach my $contract_type (sort by_type_index keys %keeper_slots)
{
  print "          <OPTION>Contract $contract_type\n";
}



print <<EOM;
        </SELECT>
      <input type=hidden name="cost$type$count" value="$cost">
      <input type=hidden name="id$type$count" value="$id">
  </td>
  <td id="player_name$count">$name</td>
  <td><Select Name="Year$count">
      </Select>
  </td>
  <td id=cost$count align=center>$cost</td>
  <td id=next_cost$count align=center>$cost2</td>
  <td id=years_left$count align=center>$years_left</td>
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

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();
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

  my $keeper_type = 'A';
  my $keeper_index = 1;
  foreach my $slot (split(/,/,$keeper_slots_raw))
  {
    my ($min,$max,$num) = split(/\|/,$slot);
    $keeper_slots{$keeper_type}->{MIN} = $min;
    $keeper_slots{$keeper_type}->{MAX} = $max;
    $keeper_slots{$keeper_type}->{NUMBER} = $num;
    $keeper_slots{$keeper_type}->{COLOR} = pop(@colors);
    $keeper_slots{$keeper_type}->{INDEX} = $keeper_index;

    $total_num += $num;
    $total_contract_types++;
    $contract_types_string .= "$keeper_type|";

    ## Alphabetically increment the type (A -> B -> C ... etc)
    $keeper_type++;
    $keeper_index++;

  }
  chop($contract_types_string);

 
  ## Get keeper prices for free-agent pickups (varies by league)
  my @fa_positions;
  @fa_positions = ('QB','RB','WR','TE','K','DEF') if ($sport eq 'football');
  @fa_positions = ('C','1B','2B','3B','SS','OF','DH','SP','RP') if ($sport eq 'baseball');
  foreach my $pos (@fa_positions)
  {
    $pos_costs{$pos}  = $league->keeper_fa_price($pos);
  }

  Header($contractStatus,$user,$team_t,$owner,$draftStatus);

  $sth = $dbh->prepare("SELECT count(*) from contracts where team='$user' and locked='yes' and league='$league_t' and years_left>0");
  $sth->execute();
  $locked_count = $sth->fetchrow_array();
  $sth->finish();

  if ($locked_count == $total_num)
  {
    print"<br>You have selected and locked all $total_num of your keepers. Good luck next season!<br>\n";
  }





print <<EOM;

  <table frame=box class=none id=contracts>
   <tr>
    <td colspan=6 align=center class=none>
     <b>$team_t</b>
    </td>
   </tr>
   <tr>
    <td>
     <b>Contract Type</b>
    </td>
    <td>
     <b>Player Name</b>
    </td>
    <td>
     <b>Years</b>
    </td>
    <td>
     <b>Current Cost</b>
    </td>
    <td>
     <b>Future Cost(s)</b>
    </td>
    <td>
     <b>Years Left on Contract </b>
    </td>
   </tr>

EOM

  $playerswon = "final_rosters";
  $sth = $dbh->prepare("SELECT w.name,w.price,w.team,w.time,p.position,p.name FROM final_rosters w, players p WHERE w.team='$team_t' AND w.league='$league_t' and w.name=p.playerid")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  $sth2 = $dbh->prepare("SELECT current_cost,total_years,years_left,team,locked,broken from contracts where player=? and league='$league_t'");
  $sth3 = $dbh->prepare("SELECT active from tags where player=? and league='$league_t'");

  $count = 0;
  my $player_years_left;
  my $cost_if_kept;
  while (($id,$bid,$bidder,$ez_time,$pos,$name) = $sth->fetchrow_array())
  { 
    $sth2->execute($id);
    ($contract_cost, $player_total_years, $player_years_left, $contract_owner, $is_locked, $is_broken) = $sth2->fetchrow_array();
    if (!defined $player_years_left)
    {
      $player_years_left = 'N/A';
    }
    $locked = ($is_locked eq 'yes') ? 1 : 0;

    ## Tags
    $sth3->execute($id);
    $active = $sth3->fetchrow();
    $player_years_left = -1 if ($active eq 'no');

    PrintPlayer($name,$id,$count,'out',$bid,$player_years_left,$pos,$contract_owner,$user,$is_broken);
    $count++;
  }   
  $sth->finish();
  $sth2->finish();
  $sth->finish();

print <<FOOTER;

  </table>
 </td>
</tr>
</table>
<br>
<br><br>
<input type="hidden" id=total name="total_players" value=$count>
<input type="hidden" id=global_lock name="global_lock" value="$contractStatus">
<input type="hidden" id=ip_flag name="ip_flag" value="$use_IP_flag">
<input type="hidden" id=league name="league" value="$league_t">

FOOTER

if ($use_IP_flag eq 'yes')
  {
print <<FOOTER1;

<p align=center>
<a name="BIDDING"><b>Enter Contracts(s) for Team $team_t</b></a>

<br>
    <input type=hidden name="TEAMS" value="$user">
    <input type=checkbox name='LOCK_ME' value='true'>$keeper_text<br>
    <input type=submit name="submit_contract" value="Assign Contract(s)" style="margin-left: auto; margin-right: auto; text-align: center;">
    <input type="reset" value="Clear The Form" id=reset1 name=reset1> 
<br>

FOOTER1
  }

##########################################################
#########User must provide team name and password#########
##########################################################
  else 
  {
print <<FOOTER2;

<br><br>

    <br>
    <table>
     <tr>
      <td align=middle>User Name</td>
      <td align=middle>Password</td>
     </tr>
     <tr>
      <td align=middle> 
       <input type="hidden" id=ip_flag name="ip_flag" value=$use_IP_flag>
       <select name="TEAMS" onChange="sndReq($league_t)">

FOOTER2
   
   ## Output each owner name as an option in the pull-down - UPDATE: change to team name?

   # default to current user (by IP check)
   $def = $user;


   #Get Team List
   $sth = $dbh->prepare("SELECT * FROM teams WHERE league = '$league_t'")
        or die "Cannot prepare: " . $dbh->errstr();
   $sth->execute() or die "Cannot execute: " . $sth->errstr();

   while (($tf_owner, $tf_name, $tf_league, $tf_adds, $tf_sport, $tf_plusminus) = $sth->fetchrow_array())
   {
     if ($tf_name eq $team_t)
     {
        $check = "selected";
     }

     PrintOwner($tf_owner,$tf_name,$check);
   }
   
   $sth->finish();

   dbDisconnect($dbh);


print <<FOOTER2;

        </select>
      </td>
      <td align=middle>
        <input type="password" name="TEAM_PASSWORD">
      </td>
     </tr>
    </table>
    <br>
    <input type=checkbox name='LOCK_ME' value='true'>$keeper_text
    <br>
    <input type=submit name="submit_contract" value="Assign Contract(s)" style="margin-left: auto; margin-right: auto; text-align: center;">
    <br>
    <input type="hidden" id=total name="total_players" value=$count>
    <input type="hidden" id=league name="league" value="$league_t">

FOOTER2
  } # end else

print <<EOM;

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
