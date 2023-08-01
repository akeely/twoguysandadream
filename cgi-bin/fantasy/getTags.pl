#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Nav_Bar;
use Leagues;
use DBTools;
use Session;
use POSIX qw(ceil floor);
use strict;

my $cgi = new CGI;

my $team_error_file = "/var/log/fantasy/team_errors.txt";
my $log = "/var/log/fantasy/getTags_LOG.txt";
my $tag_text = "Lock My Tagged Player!";
my $errorflag = 0;


## Set up Franchise/Transition position costs
my %franchise;
my %transition;
my @player_costs;
my $player_costs_str;
my @loop_pos = ();

########################
#
# Header Print
#
########################

sub Header($$$$$$$)
{
  my $global_lock = shift;
  my $head_user = shift;
  my $head_team = shift;
  my $sport = shift;
  my $is_commish = shift;
  my $draft_status = shift;
  my $league = shift;

  print "Cache-Control: no-cache\n";
  print "Content-type: text/html\n\n";

print <<HEADER;

<HTML>
<HEAD>
<TITLE>Player Tags Page</TITLE>

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

   var http = createRequestObject()

function snd_check_tags()
{

    if (tag_form.ip_flag.value == 'yes')
    {
      var sendme = tag_form.TEAMS.value + ";" + tag_form.league.value;
    }
    else
    {
      var sendme = tag_form.TEAMS.options[tag_form.TEAMS.selectedIndex].value + ";" + tag_form.league.value;
    }
    http.open('GET','checkUserTags.pl?action='+sendme)
    http.onreadystatechange = check_tags
    http.send(null)
}

function pswd_checker()
{
  if (tag_form.ip_flag.value != 'yes')
  {
    if (tag_form.TEAM_PASSWORD.value == '')
    {
      alert("Please enter a password")
      return (false);
    }

    if (tag_form.TEAMS.value == 'Select A Team')
    {
      alert("Please select a Team")
      return (false)
    }
  }

  return(table_update(1))
}

function table_update(submitted)
{
  var args = new Array();
  var status = '20% Increase';

  var clear = false
  var player = tag_form.player_select.selectedIndex;
  var option_text = (player == -1) ? 'NONE' : tag_form.player_select.options[player].value;
  if ((player == -1) || (option_text == 'NONE'))
  {
    if (submitted == 1)
    {
      clear = confirm("This will clear any existing tag selection. Proceed?")
    }
    if (!clear) 
    {
      return(false)
    }
  }

  if (option_text != 'NONE')
  {
    args = option_text.split(' - ');
    player_name = args[0];
    player_pos = args[1];

    if (tag_form.tag_type[0].checked)
    {
      var tag = tag_form.tag_type[0].value
      var tag_text = 'Franchise'
    }
    else if (tag_form.tag_type[1].checked)
    {
      var tag = tag_form.tag_type[1].value
      var tag_text = 'Transition'
    }
    else
    {
      if ((submitted == 1) && (!clear))
      {
        alert('Select a Tag Type!')
      }
      return(false);
    }
    var current_costs = new Array ($player_costs_str);
    var new_cost = Math.ceil(current_costs[player] * 1.2);

    avg_cost = document.getElementById(tag+"_"+player_pos).innerHTML
    if (avg_cost > new_cost)
    {
      new_cost = avg_cost;
      status = 'League-wide Average'
    }
    
    tags.rows[2].cells[2].innerHTML='<b>'+tag_text+' Tag</b><br>'+player_name+' for '+new_cost+'<br>('+status+')';
  }
  else
  {
    player_name='NONE';
    new_cost=0;
    player_pos='NONE';

    tag_form.player_name.value='NONE'
    tag_form.player_cost.value=0;
    tag_form.player_pos.value='NONE';

    tags.rows[2].cells[2].innerHTML='<b>NONE</b>';
  }

  if (submitted == 1)
  {
    tag_form.player_name.value=player_name;
    tag_form.player_cost.value=new_cost;
    tag_form.player_pos.value=player_pos;
  }
  
  if ((tag_form.LOCK_ME.checked) && (submitted == 1) &&(!clear))
  {
    var answer = confirm("This will LOCK your tagged player for this offseason. Continue?")
    if (!answer)
    {
      return(false);
    }
    else
    {
      return(true);
    }
  } // end if ((tag_form.LOCK_ME.checked) && (submitted == 1))

  return(true)
} // end table_update


function check_tags() 
{
  if(http.readyState == 4)
  {
    var response = http.responseText
    var update = new Array()
    var players = new Array()
    var table_size = (player_select.options.length);
    var global_lock = tag_form.global_lock.value;

    if(response.indexOf(';') != -1) 
    {
      update = response.split(';')
    }

    for (var i = 0; i < (update.length); i++)
    {
      players[i] = update[i].split(',')
    }

    // Disable forms if league contracts/tags are locked
    if (global_lock == 1)
    {
      player_select.disabled = true;
      eval(tag_form.tag_type[0].disabled=true)
      eval(tag_form.tag_type[1].disabled=true)
      eval(tag_form.submit_tag.disabled=true)
      eval(tag_form.LOCK_ME.disabled=true)
      eval(tag_form.reset1.disabled=true)
      return
    }

    var player_length = (players.length-1);
    var row_count =1;
    var break_me = 0;
    for (var i = 0; i < (table_size); i++)
    {
      p_select = "player_select.options"
      text = p_select + "[i].text";
      name = eval(text)

      for (var j = 0; j<player_length; j++)
      {
        // If the player has been tagged
        if (name == players[j][0])
        {
          player_select.selectedIndex = i;

          if (players[j][1] == 'F')
            tag_form.tag_type[0].checked = true
          else
            tag_form.tag_type[1].checked = true

          // Add some color to signal the player status
          tags.rows[2].cells[2].style.backgroundColor = "green"

          // Disable form if tagged player is locked
          if (players[j][2] == '1')
          {
            player_select.disabled = true;
            eval(tag_form.tag_type[0].disabled=true)
            eval(tag_form.tag_type[1].disabled=true)
            eval(tag_form.submit_tag.disabled=true)
            eval(tag_form.LOCK_ME.disabled=true)
            eval(tag_form.reset1.disabled=true)
          }
          
          break_me=1
          break
        } // end if (name == players[j][0])
      } // end for-loop (j)

      if (break_me == 1)
        break

    } // end for-loop (i)

  table_update(0)
  } // end if(http.readyState == 4)
} // end check_tags
-->
</script>


<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY onLoad="snd_check_tags()">
<p align=center>

HEADER

  my $nav = Nav_Bar->new('Keeper Tags',$head_user,$is_commish,$draft_status,$head_team);
  $nav->print();

print <<HEADER;

<center>
<br>
<b>Franchise/Transition Tags</b><br>
This page allows you to apply either a Franchise or Transition tag to one of your keeper league players.<br>
<table>
<tr>
 <td align=center>The Franchise Tag</td>
 <td align=center>The Transition Tag</td>
</tr>
<tr>
 <td>
  At the conclusion of the season, a manager may designate 1 player from their 
  current roster as a " Franchise Player" (FP). To designate an FP, the manager 
  must make a qualifying offer equal to the average salary of the top 3 
  players of the same position from the previous year, or a 20% increase from 
  the player's current salary, whichever is greater. A player may not be 
  designated a FP for more than 1 consecutive year. A FP will be designated an 
  UFA at the conclusion of the season. 
 </td>
 <td>
  If a manager choses not to use the Franchise Tag, the manager may designate 
  1 player from their current roster to be a "Transition Player" (TP). To 
  designate a TP, the manager must make a qualifying offer equal to the 
  average salary of the top 6 players from the previous year, or a 20% 
  increase from the player's current salary, whichever is greater. The TP is 
  then designated a RFA, with an initial bid equal to the qualifying offer. 
 </td>
</tr>
</table>

<br>Current Prices Per Position for $league:<br>
<table name='pos_costs' id='pos_costs'>
 <tr>
  <td>Positon</td>
  <td>Franchise Avg Salary</td>
  <td>Transition Avg Salary</td>
 </tr>
HEADER

  foreach (@loop_pos)
  {
print <<POS;
 <tr>
  <td>$_</td>
  <td name="F_$_" id="F_$_">$franchise{$_}</td>
  <td name="T_$_" id="T_$_">$transition{$_}</td>
 </tr>
POS
  }

print "</table>\n";
print "<br>\n";

if ($global_lock eq 'Yes')
{
  print "<br><br><h3> The Contract Assignment Period has ended. All contracts/tags are now locked until next year. </h3> <br>\n";
}

print <<HEADER;

<form action="/cgi-bin/fantasy/putTags.pl" method="post" id=tag_form onSubmit='return table_update(1)'>
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

my ($ip,$sess_id,$sport_t,$leagueid, $teamid, $ownerid, $ownername, $teamname) = checkSession();
my $dbh = dbConnect();
  
#Get League Data
  my $league = Leagues->new($leagueid,$dbh);
  if (! defined $league)
  {
    die "ERROR - league object not found ($leagueid)!\n";
  }


  my $sth = $dbh->prepare("select w.price from players_won w, players p where w.leagueid=$leagueid and w.playerid=p.playerid and p.position=? order by w.price desc");

  ## Get Franchise & Transition costs
  if ($sport_t eq 'baseball')
  {
    @loop_pos = ('C','1B','2B','3B','SS','OF','DH','SP','RP');
  }
  elsif ($sport_t eq 'football')
  {
    @loop_pos = ('QB','RB','WR','TE','K','DEF');
  }
  foreach (@loop_pos)
  {
    my $this_cost = 0;
    $sth->execute($_);
    for (my $c=0;$c<=2;$c++)
    {
      $this_cost += $sth->fetchrow();
    }
    $franchise{$_}  = ceil($this_cost/3);

    ## "this_cost" is not reset - simply grab the next three players, and divide the total by 6 for the transition value
    for (my $c=0;$c<=2;$c++)
    {
      $this_cost += $sth->fetchrow();
    }
    $transition{$_}  = ceil($this_cost/6);
  }
  $sth->finish();


  my $sth_prices = $dbh->prepare("SELECT w.price FROM final_rosters w WHERE w.teamid=$teamid AND w.leagueid=$leagueid and not exists (select 'x' from contracts where leagueid=w.leagueid and playerid=w.playerid and years_left != -1) and not exists (select 'x' from tags where leagueid=w.leagueid and playerid=w.playerid and active='no') order by w.playerid");
  $sth_prices->execute();
  while (defined(my $bid = $sth_prices->fetchrow()))  ## need the 'defined' here for zero-values
  {
    push(@player_costs,$bid);
  }   
  $sth_prices->finish();
  $player_costs_str = join(',',@player_costs);


  my $contractStatus = $league->keepers_locked();
  my $draftStatus = $league->draft_status();
  my $use_IP_flag = $league->sessions_flag();
  Header($contractStatus,$ownername,$teamname,$sport_t,$league->owner() == $ownerid,$draftStatus,$league->name());

  $sth = $dbh->prepare("SELECT playerid,locked from tags where leagueid=$leagueid and ownerid=$ownerid and active='yes'");
  $sth->execute();
   my ($curr_name, $locked_status) = $sth->fetchrow_array();
  $sth->finish();

  my $form_enabled = 1;
  if (defined $curr_name)
  {
    if ($locked_status eq 'yes')
    {
      print "<br>You have selected and locked your tagged player. Good luck next season!<br>\n";
      $form_enabled = 0;
    }
  }

print <<EOM;

  <table frame=box class=none id=tags>
   <tr>
    <td colspan=6 align=center class=none>
     <b>$teamname</b>
    </td>
   </tr>
   <tr>
    <td>
     <b>Player Name</b>
    </td>
    <td>
     <b>Tag Type</b>
    </td>
    <td>
     <b>Result of Proposed Tag Choice</b>
    </td>
   </tr>
   <tr>
    <td rowspan=5>
     <select name="player_select" id="player_select" size="5" onChange='table_update(0)'>
EOM

  $sth = $dbh->prepare("SELECT p.name,p.playerid,w.price,p.position FROM final_rosters w, players p WHERE w.teamid=$teamid AND w.leagueid=$leagueid and w.playerid=p.playerid and not exists (select 'x' from contracts where leagueid=w.leagueid and playerid=w.playerid and years_left != -1) and not exists (select 'x' from tags where leagueid=w.leagueid and playerid=w.playerid and active='no') order by w.playerid");
  $sth->execute();

open(LOG,">$log");
  
  my $hidden_id_lut = '';
  while (my ($name,$id,$bid,$pos) = $sth->fetchrow_array())
  { 
    print "       <option>$name - $pos\n";

    ## Build a string (to be printed below) to keep look-up for player name to ID
    $hidden_id_lut .= "<input type='hidden' name='${name}_id' value='$id'>\n";

  }   
  $sth->finish();
close(LOG);

print <<EOM;

     <option>NONE</option>
   </select>

$hidden_id_lut
   </td>
   <td>
    <input type='radio' name='tag_type' value='F' onChange='return table_update(0)'>Franchise<br><br>
    <input type='radio' name='tag_type' value='T' onChange='return table_update(0)'>Transition
   </td>
   <td align=center>
    Result will go here!
   </td>
  </tr>
  </table>
 </td>
</tr>
</table>
<br>
<br><br>

EOM


if ($use_IP_flag eq 'yes')
  {
print <<FOOTER1;

<p align=center>
<a name="BIDDING"><b>Assign Tag for Team $teamname</b></a>

<br>
    <input type=hidden name="TEAMS" value="$ownerid">
    <input type=checkbox name='LOCK_ME' value='true'>$tag_text<br>
    <input type=submit name="submit_tag" value="Assign Tag" style="margin-left: auto; margin-right: auto; text-align: center;">
    <input type="reset" value="Clear The Form" id=reset1 name=reset1> 
<br>
    <input type="hidden" id=league name="league" value="$leagueid">
    <input type="hidden" id=global_lock name="global_lock" value=$contractStatus>
    <input type="hidden" id="ip_flag" name="ip_flag" value=$use_IP_flag>
    <input type="hidden" id="player_name" name="player_name" value="">
    <input type="hidden" id="player_id" name="player_id" value="">
    <input type="hidden" id="player_cost" name="player_cost" value="">
    <input type="hidden" id="player_pos" name="player_pos" value="">

FOOTER1
  }

print <<EOM;

</center>
</div>
</form>

EOM

Footer();
