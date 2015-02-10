#!/usr/bin/perl
use DBI;
use CGI;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use Leagues;
use Nav_Bar;
use Session;
use DBTools;

# script to generate auction team pages

# files
$team_error_file = "/var/log/fantasy/team_errors.txt";
$roster_error_file = "/var/log/fantasy/roster_errors.txt";

#globals
my $dbh;
my %positions;
my %sortvals = (
                 'C'       => 1,
                 '1B'      => 2,
                 '2B'      => 3,
                 '3B'      => 4,
                 'SS'      => 5,
                 'Util_IN' => 6,
                 'OF'      => 7,
                 'Util_OF' => 8,
                 'Util'    => 9,
                 'SP'      => 10,
                 'RP'      => 11,
                 'P'       => 12,
                 'B'       => 13
               );


#############################
#
# Header
#
#############################

sub Header($$$$)
{

 my $head_user = shift;
 my $head_team = shift;
 my $league_owner = shift;
 my $draft_status = shift;

print <<HEADER;

<HTML>
<HEAD>
<TITLE>Team Page</TITLE>

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
var current_table = 'players_won';
var other_table = 'final_rosters';

function set_table(tablename,othertable) {
  current_table = tablename;

  var node=document.getElementById(othertable);
  node.style.backgroundColor = '';

  node=document.getElementById(tablename);
  node.style.backgroundColor = 'green';
}


function sndReq() {
    var team_name = contract_form.TEAMS.options[contract_form.TEAMS.selectedIndex].value
    var sendme = current_table + ";" + team_name + ";" + contract_form.league.value;
    contract_form.TEAMS.disabled = true;
    http.open('GET','getReqRoster.pl?action='+sendme)
    http.onreadystatechange = printRoster
    http.send(null)
}

function printRoster()
{

  if(http.readyState == 4)
  {
    var response = http.responseText
    var update = new Array()
    var players = new Array()
    var my_players = new Array()

    var the_team = contract_form.TEAMS.options[contract_form.TEAMS.selectedIndex].value

    if (response.indexOf(';') != -1) 
    {
      update = response.split(';')
    }
    var info = update[0].split(':');
    my_players = update[1].split(',');
    
    owner_names = info[0].split('/');
//    team_name.innerHTML = owner_names[1];
    var owner = document.getElementById('owner');
    owner.innerHTML = owner_names[0];
    email.innerHTML = info[1];
    cash.innerHTML = info[2];

    if (current_table == 'final_rosters')
    {
      cash.innerHTML = 'N/A';
    }

    for (var i = 0; i < (my_players.length); i++)
    {
      players[i] = my_players[i].split(':')
    }

    var player_length = (players.length - 1);
    var this_player = new Array();
    for (var i = 1; i <= player_length ; i++)
    {
      this_player = players[i][0].split('|');
      if (this_player[2] == 1)
      {
        this_player[1] = this_player[1] + '  <b>(K)</b>';
      }
      else if (this_player[2] == -1)
      {
        this_player[1] = this_player[1] + '  <b>(Exp)</b>';
      }

      text = "Pos_" + players[i][1] + ".innerHTML = this_player[1]";
      eval(text)
      text = "Cost_" + players[i][1] + ".innerHTML = players[i][2]";
      eval(text)

    }
    contract_form.TEAMS.disabled = false;    
  }
}
-->
</script>


<LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY onLoad="sndReq()">

HEADER

  my $is_commish = ($league_owner eq $head_user) ? 1 : 0;
  my $nav = Nav_Bar->new('Rosters',"$head_user",$is_commish,$draft_status,"$head_team");
  $nav->print();

}

#############################
#
# Header2
#
#############################

sub Header2()
{

  ## Check if this league has results in final_roster table
  $sth_final_check = $dbh->prepare("SELECT count(1) FROM final_rosters WHERE league = '$league_t'");
  $sth_final_check->execute();
   my $final_count = $sth_final_check->fetchrow();
  $sth_final_check->finish();
  
  my $final_text = 'End-of-Season Rosters';
  my $final_script = "set_table('final_rosters','players_won'); sndReq(); return false;";
  if ($final_count > 0)
  {
    $final_text .= " (UNAVAILABLE)";
    $final_script = "return false;";
  }

print <<HEADER2;

<br>

</p>

<p>
<table align="center" class=none cellpadding=30 cellspacing=5 id="rosterlink">
 <tr>
  <td style="background-color:green" id='players_won'><a href="#" onclick="set_table('players_won','final_rosters'); sndReq(); return false;">Post-Draft Roster</a></td>
  <td id='final_rosters'><a $hide_final href="#" onclick="$final_script">$final_text</a></td>
 </tr>
</table>
</p>
 
<form action="/cgi-bin/fantasy/putContracts1.pl" method="post" id=contract_form>
<table cellpadding=25 cellspacing=15 align="center" class=none id="roster2">

HEADER2

}


#############################
#
# Print Player Row
#
#############################

sub PrintPlayerRow($){
   my $position = shift;

print <<ROSTER;

        <tr>
          <td align="center"><b>$position:</b></td>
          <td align="center" id="Pos_$position">
            $name
          </td>
          <td align="center" id="Cost_$position">
        </tr>

ROSTER

}


#############################
#
# Print Roster
#
#############################

sub PrintRoster($$){
   my $league_t = shift;
   my $team_t = shift;

print <<ROSTER;
  <tr>
    <td class=none>
      <table frame="box" id="roster">
        <tr>
          <td align="center"><b>Team:</b></td>
          <td align="center" colspan=2><select style="text-align:center" name="TEAMS" onChange="sndReq()">
ROSTER

    ## Connect to teams table
    $sth = $dbh->prepare("SELECT name, owner FROM teams WHERE league = '$league_t'")
       or die "Cannot prepare: " . $dbh->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    while (($tf_name, $tf_owner) = $sth->fetchrow_array())
    {

print <<FOOTER;

  <option style="text-align:center" value="$tf_owner"> 
  $tf_name
  </option>

FOOTER

    }
    $sth->finish();

print <<ROSTER;

          </select></td>
        </tr>
        <tr>
          <td align="center"><b>Owner:</b></td>
          <td align="center" name="owner" id="owner" colspan=2></td>
        </tr>
        <tr>
          <td align="center"><b>Email:</b></td>
          <td align="center" name="email" id="email" colspan=2></td>
        </tr>
        <tr>
          <td align="center"><b>Cash Remaining:</b></td>
          <td align="center" name="cash" id="cash" colspan=2></td>
        </tr>

ROSTER
   

    foreach my $pos (sort by_pos keys %positions)
    {
      ##PrintPlayerRow($pos,$positions{"$pos"});
      PrintPlayerRow($pos);
    }

print <<ROSTER;

      </table>
    </td>
   </tr>

ROSTER

}


#############################
#
# Make Roster
#
#############################

sub MakeRoster($$$)
{
   my $sport = shift;
   my $league = shift;
   my $team = shift;

   if ($sport eq "baseball")
   {
      %positions = ( 'C'   => " ",
                     '1B'  => " ",
                     '2B'  => " ",
                     '3B'  => " ",
                     'SS'  => " ",
                     'OF'  => " ",
                     'SP'  => " ",
                     'RP'  => " "
                   ); 
   }
   elsif ($sport eq "football")
   {
      %positions = ( 'QB'  => " ",
                     'RB'  => " ",
                     'RB2' => " ",
                     'WR'  => " ",
                     'WR2' => " ",
                     'TE'  => " ",  
                     'K'   => " ",
                     'DEF' => " "
                   );
   }

   my $sth_roster = $dbh->prepare("select position from positions where league='$league'");
   $sth_roster->execute();
   while ( my $pos = $sth_roster->fetchrow() )
   {
      # Add user-selected positions
      $positions{$pos} = " ";
   }
   $sth_roster->finish();

   PrintRoster($league,$team);
}

################################
#
# Footer
#
################################

sub Footer($)
{

my $league_num = shift;

print <<FOOTER;

</table>

<input type=hidden name="league" value="$league_num">
</form>
</center>

</BODY>
</HTML>

FOOTER

}

######################
#
# Print Hidden
#
######################


sub PrintHidden($)
{
my $field = shift;

print <<EOM;

<input type="hidden" name="session" value="$field">

EOM

}


#######################################
#
# Main Function
#
#######################################
$set = 0;

my ($my_ip,$namer,$pswd,$my_id,$team,$sport,$league_t) = checkSession();
$dbh= dbConnect();

print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";

#Get League Data
$league = Leagues->new($league_t,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}


Header($namer,$team,$league->{_OWNER},$league->{_DRAFT_STATUS});

Header2();

MakeRoster($sport, $league_t, $team);


Footer($league_t);
$sth->finish();
dbDisconnect($dbh);



sub by_pos
{
  my $a_temp = $a;
  $a_temp =~ s/\d+$//g;
  my $b_temp = $b;
  $b_temp =~ s/\d+$//g;

  my $val_a = $sortvals{$a_temp};
  my $val_b = $sortvals{$b_temp};

  if ($val_a == $val_b)
  {
    my $a_tiebreak=-1;
    my $b_tiebreak=-1;

    $a_tiebreak = $1 if ($a =~ m/.*(\d+)/);
    $b_tiebreak = $1 if ($b =~ m/.*(\d+)/);

    return ($a_tiebreak <=> $b_tiebreak);
  }
  else
  {
     return ($val_a <=> $val_b);
  }
}
