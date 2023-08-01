#!/usr/bin/perl

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use DBTools;
use Session;

$drafting_color = "#54C571";
$keeping_color = "#FBB117";
$stagnant_color = "#F75D59";
$change_color = "#33FFFF";
$cancel_color = "#CC0066";

my ($my_ip,$my_id,$sport_t,$leagueid, $teamid, $ownerid, $ownername, $teamname) = checkSession();
my $dbh = dbConnect();

my $sth = $dbh->prepare("Select name, passwd, email from passwd where id=$ownerid");
$sth->execute();
my ($owner_name, $owner_password, $owner_email) = $sth->fetchrow_array();
$sth->finish();

## For my amusement!
my @comedic_names = ("Scumbag","Anti-Semite","Sparky","Punk","Rick Steve","Lollygagger","Doppleganger","Joe Morgan Lover","Muffin Ass","Hasslehoff","Fantasy Guru","Team Player","Third Wheel","Prince of Parties","Apollo","Benedict Arnold","Lassie","Cobra Commander","Ringbearer","Jerkface","Eagles Fan","noob","Bisquick","Chicken of the Sea","Jedi Knight","Sith Lord","Donut","Lonely Girl","Pipsqueak","\$team_name");

my $random_index = int((rand() * @comedic_names));

my $opener = "Hey There, <font color='#FF9999'>$comedic_names[$random_index]</font>!";

my $passwd_stars = '';
for ($x = 0; $x < length($owner_password); $x++)
{
  $passwd_stars .= '*';
}

print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";
print <<EOM;

<HTML>
<HEAD>
<TITLE>"Can't Miss" Fantasy Sports</TITLE>
<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="-1">

<script language="JavaScript">
<!--
function createRequestObject() {

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

function changeMe(table,row,hinge)
{
  if (table.rows[row].cells[3].style.display == 'none')
  {
    table.rows[row].cells[3].style.display='table'
    table.rows[row].cells[2].innerHTML = '<b>Cancel</b>'
    table.rows[row].cells[2].style.backgroundColor = '$cancel_color'

    if (hinge == 1)
    {
      change_form.user_sport.disabled=true
      row = row + 3
      change_cmd = "change_form.val" + row
      var index = change_form.user_sport.selectedIndex
      var team_text = change_form.user_sport.options[index].text
      var team_data = team_text.split(' - ')
      eval(change_cmd + ".value='" + team_data[0] + "'")
    }
    change_cmd = "change_form.val" + row
    eval(change_cmd + ".focus()")
    eval(change_cmd + ".select()")
    
  }
  else
  {
    table.rows[row].cells[3].style.display='none'
    table.rows[row].cells[2].innerHTML = '<i>Change</i>'
    table.rows[row].cells[2].style.backgroundColor = '$change_color'

    if (hinge == 1)
    {
      row = row + 3
      change_form.user_sport.disabled=false
    }
    change_cmd = "change_form.val" + row + ".value"
    eval(change_cmd+'=""')
  }
}

function clearFields()
{
  change_form.val0.value=''
  change_form.val1.value=''
  change_form.val2.value=''
  change_form.val3.value=''

  submit_val = change_form.user_sport.options[change_form.user_sport.selectedIndex].value
  parent.location.href="/cgi-bin/fantasy/putTeam.pl?user_sport="+submit_val
}

// Called onSubmit by this page - catches changes made to owner fields
// If change made, will apply the changes and show new result
function checkChanges()
{
  var change_requested = '0'
  var change_fields = new Array()
  var change_values = new Array()

  for (var i = 3; i>=0; i--)
  {
    var change_cmd = "change_form.val" + i + ".value"
    var change_val = eval(change_cmd)
    var curr_val
    if (i < 3)
    {
      curr_val = info_table.rows[i].cells[1].firstChild.nodeValue
    }
    else
    {
      curr_val_text = change_form.user_sport.options[change_form.user_sport.selectedIndex].text
      curr_vals = curr_val_text.split(' - ')
      curr_val = curr_vals[0]
    }
    
 
    if ((change_val != '') & (change_val != curr_val))
    {
      var change_obj = eval("change_form.hidden" + i + ".value")
      change_fields.push(change_obj)
      change_values.push(change_val)
      
      change_requested = '1'
      
    }
  }


  if (change_requested == '0')
    return(true)

  // If a change was requested, send it to the server to update data
  varLine = 'changeData.pl?'
  for (var i = 0; i<change_fields.length; i++)
  {
    if (varLine != 'changeData.pl?')
      varLine += '&'
    varLine += change_fields[i] + '=' + change_values[i]
  }

  varLine += '&real_owner=$ownername'
  curr_val_text = change_form.user_sport.options[change_form.user_sport.selectedIndex].text
  curr_vals = curr_val_text.split(' - ')
  curr_val = curr_vals[1]
  varLine += '&real_league='+curr_val

  http.open('GET',encodeURI(varLine))
  http.onreadystatechange = handleResponse
  http.send(null)

  return(false)
}


function handleResponse()
{
    if(http.readyState == 4)
    {
        var response = http.responseText
        var changes=response.split(';')
        var alertText=''

        for (var x=0;x<changes.length;x++)
        {
          change=changes[x].split('=')
          if (change[0] == 'owner')
          {
            info_table.rows[0].cells[1].firstChild.nodeValue = change[1]
            alertText += "Owner name has been changed!\\n"
          }
          if (change[0] == 'team')
          {
            change_data = change[1].split(',')
            change_form.user_sport.options[change_form.user_sport.selectedIndex].text=change_data[1]+' - '+change_data[0]

            var old_optVal = change_form.user_sport.options[change_form.user_sport.selectedIndex].value
            oldOptVals = old_optVal.split(':')
            change_form.user_sport.options[change_form.user_sport.selectedIndex].value=change_data[1]+':'+oldOptVals[1]+':'+oldOptVals[2]
            alertText += "Team name has been changed!\\n"
          }
          if (change[0] == 'email')
          {
            info_table.rows[1].cells[1].firstChild.nodeValue = change[1]
            alertText += "Email address has been changed!\\n"
          }
          if (change[0] == 'password')
          {
            password_stars=''
            for (var i=0; i<change[1].length; i++)
              password_stars += '*'
 
            info_table.rows[2].cells[1].firstChild.nodeValue = password_stars
            alertText += "Password has been changed!\\n"
          }
        }
        change_form.user_sport.disabled = false
        alert(alertText)
    }
}

</script>

</HEAD>
<BODY>
<h2 align=center>$opener</h2>
<br>

<form id='change_form' onSubmit="return checkChanges()" action="/cgi-bin/fantasy/putTeam.pl" method="post" target="_top">

<table align="center" ID="Table1" cellspacing=10 border="2" class=none>
         <tr>
            <td class=none><a href="/fantasy/fantasy_main_index.htm" target="_top">Fantasy Main</a></td>
            <td class=none><a href="/fantasy/create_league_index.htm" target="_top">Create New League</a></td>
            <td class=none><a href="/fantasy/join_league_index.htm" target="_top">Join Created League</a></td>
            <td class=none><a href="/cgi-bin/fantasy/logout.pl" target="_top">Logout</a></td>
         </tr>
      </table>

<br><br>

<p align=center>
<table id='info_table'>
 <tr>
  <td>Owner Name</td>
  <td>$ownername</td>
  <td STYLE='background-color: $change_color' onClick='changeMe(info_table,0,0)'><i>Change</i></td>
  <td style="display:none"><input type='text' maxlength='50' name='val0' value='$ownername'><input type='hidden' name='hidden0' value='owner'>
 </tr>
 <tr>
  <td>Owner Email</td>
  <td>$owner_email</td>
  <td STYLE='background-color: $change_color' onClick='changeMe(info_table,1,0)'><i>Change</i></td>
  <td style="display:none"><input type='text' maxlength='30' name='val1' value='$owner_email'><input type='hidden' name='hidden1' value='email'>
 </tr>
 <tr>
  <td>Owner Password</td>
  <td>$passwd_stars</td>
  <td STYLE='background-color: $change_color' onClick='changeMe(info_table,2,0)'><i>Change</i></td>
  <td style="display:none"><input type='text' maxlength='16' name='val2'><input type='hidden' name='hidden2' value='password'>
 </tr>
</table>
<br><br>

<u>Team Clubhouse(s):</u>
<table>
 <tr>
  <td STYLE='background-color: $drafting_color'>Leagues Drafting </td>
  <td> | </td>
  <td STYLE='background-color: $keeping_color'>Leagues With Keepers Open </td>
  <td> | </td>
  <td STYLE='background-color: $stagnant_color'>Stagnant Leagues</td>
 </tr>
</table>

<table id='teams_table' align=center>
 <tr>
  <td rowspan=2>Clubhouse</td>
  <td rowspan=2>
   <select name="user_sport">
EOM

#  ## Get any teams currently drafting
  $sth = $dbh->prepare("SELECT t.name, t.id, t.leagueid, l.name, t.sport FROM teams t, leagues l WHERE t.ownerid = $ownerid and l.draft_status in ('open','paused') and t.leagueid=l.id")
       or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();

  $teams_count = 0;
  my $init_val = '';
  while (($tf_name, $tf_id, $tf_league, $tf_leaguename, $tf_sport) = $sth->fetchrow_array())
  {
    print "<option value='$tf_id:$tf_sport:$tf_league' STYLE='background-color: $drafting_color'>$tf_name - $tf_leaguename</option>";
    $init_val = $tf_name if ($teams_count == 0);
    $teams_count++;
  }
  $sth->finish();

  ## Get any teams that can select keepers
  $sth = $dbh->prepare("SELECT t.name, t.id, t.leagueid, l.name, t.sport FROM teams t, leagues l WHERE t.ownerid = $ownerid and l.keepers_locked='no' and l.draft_status='closed' and t.leagueid=l.id")
       or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();

  while (($tf_name, $tf_id, $tf_league, $tf_leaguename, $tf_sport) = $sth->fetchrow_array())
  {
    print "<option value='$tf_id:$tf_sport:$tf_league' STYLE='background-color: $keeping_color'>$tf_name - $tf_leaguename</option>";
    $init_val = $tf_name if ($teams_count == 0);
    $teams_count++;
  }
  $sth->finish();

  ## Get any remaining (dormant) teams
  $sth = $dbh->prepare("SELECT t.name, t.id, t.leagueid, l.name, t.sport FROM teams t, leagues l WHERE t.ownerid = $ownerid and l.keepers_locked='yes' and l.draft_status='closed' and t.leagueid=l.id order by l.id desc")
       or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();

  while (($tf_name, $tf_id, $tf_league, $tf_leaguename, $tf_sport) = $sth->fetchrow_array())
  {
    print "<option value='$tf_id:$tf_sport:$tf_league' STYLE='background-color: $stagnant_color'>$tf_name - $tf_leaguename</option>";
    $init_val = $tf_name if ($teams_count == 0);
    $teams_count++;
  }
  $sth->finish();

print <<EOM;
   </select>
  </td>
  <td rowspan=2 STYLE='background-color: $change_color' onClick='changeMe(teams_table,0,1)'><i>Change</i></td>
  <td rowspan=2 style="display:none"><input type='text' maxlength='50' name='val3' value="$init_val"><input type='hidden' name='hidden3' value='team'>
 </tr>
</table>
<br>

<input type='button' value='Apply Change(s)' onClick='checkChanges()'>
<input type='button' value='Enter This Clubhouse' onClick='clearFields()'>
<input type='submit' style="display:none">

</form>

<br><br>
</p>

</BODY>
</HTML>


EOM

dbDisconnect($dbh);

