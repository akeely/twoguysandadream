#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use Leagues;
use DBTools;
use Session;

my $cgi = new CGI;
#variables that will be used later.

$errors = "/var/log/fantasy/create_league_errors1.txt";
$this_errors = "/var/log/fantasy/create_league_errors2.txt";
$log = "/var/log/fantasy/createNewLeague1_log.txt";
$return = "/fantasy/fantasy_main_index.htm";
$errorflag = 0;

open (FILE, ">$errors");
 flock(FILE,2);
 print FILE "\n";
close(FILE);

## Input Variables
$in_leagueName = $cgi->param('leagueName');
$in_leaguePassword = $cgi->param('leaguePassword');
$in_teamName = $cgi->param('teamName');
$in_draftType = $cgi->param('draftType');
$in_keeper = $cgi->param('Keeper');
$in_keeper_leagueName = $cgi->param('keeper_leagueName');
$in_keeper_leaguePassword = $cgi->param('keeper_leaguePassword');
$in_keeper_name_persist = $cgi->param('name_persist');
$in_sport = $cgi->param('sport');

$import_contracts = 'no';
my %defaults = (
  'salary_cap' => '0',
  'max_members' => '0',
  'keeper_increase' => '0',
);
my %poss;
my $poss_string;
my %cats;
my $cats_string;
my %fa_prices;
my $con_count=0;


my ($ip,$sess_id,$sport_t,$leagueid, $teamid, $ownerid, $ownername, $teamname) = checkSession();

my $dbh = dbConnect();

## Make sure that the owner has entered a league name
if (($in_leagueName =~ /^$/) || (length($in_leagueName) > 25))
{
  open (FILE,">>$errors");
  flock(FILE,2);
  print FILE "<b>Please enter a valid League Name (25 character limit)!</b>\n";
  close(FILE);
  $errorflag = 1;
}
else
{
  # Check for duplicate League Name
  $league_count = 0;
  $sth = $dbh->prepare("SELECT count(1) FROM leagues WHERE name = '$in_leagueName'")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  $league_count = $sth->fetchrow();
  $sth->finish();
  
  if ($league_count != 0)
  {
    open (FILE,">>$errors");
    flock(FILE,2);
    print FILE "<b>League Name <i>$in_leagueName</i> is already taken!</b>\n";
    close(FILE);
    $errorflag = 1;
  }
}

if (($in_leaguePassword =~ /^$/) || (length($in_leaguePassword) < 4))
{
   open (FILE, ">>$errors");
   flock(FILE,2);
   print FILE "<b>Please enter a League Password of at least four characters!</b>\n";
   close(FILE);
   $errorflag = 1;
}

if ((($in_teamName =~ /^$/) || (length($in_teamName) > 18)) && ($in_keeper_name_persist ne 'yes'))
{
   open (FILE, ">>$errors");
   flock(FILE,2);
   print FILE "<b>Please enter a valid name for your new team (18 character max)!</b>\n";
   close(FILE);
   $errorflag = 1;
}

if(($in_draftType ne "Auction") && ($in_draftType ne "Snake"))
{
   open (FILE, ">>$errors");
   flock(FILE,2);
   print FILE "<b>Please select a draft type!</b>\n";
   close(FILE);
   $errorflag = 1;
}

if(($in_sport ne "baseball") && ($in_sport ne "football") && ($in_sport ne "basketball"))
{
   open (FILE, ">>$errors");
   flock(FILE,2);
   print FILE "<b>Please select a sport!</b>\n";
   close(FILE);
   $errorflag = 1;
}

if (($in_keeper eq 'yes') && ($in_keeper_leagueName !~ /^$/))
{
  #Get League Data
  my $sth_fetch_leagueid = $dbh->prepare("select id from leagues where name='$in_keeper_leagueName'");
  $sth_fetch_leagueid->execute();
  $prev_leagueid = $sth_fetch_leagueid->fetchrow();
  $sth_fetch_leagueid->finish();

  $league = Leagues->new($prev_leagueid,$dbh);
  if (! defined $league)
  {
    die "ERROR - league object not found!\n";
  }

  ## Check if this owner was in the keeper league being imported
  $sth_team_check = $dbh->prepare("Select count(1) from teams where leagueid=$prev_leagueid and ownerid=$ownerid");
  $sth_team_check->execute();
  $team_conf = $sth_team_check->fetchrow();
  $sth_team_check->finish();

  if ($league->{_PASSWORD} =~ /^$/)
  {
    open (FILE, ">>$errors");
    flock(FILE,2);
    print FILE "<b>Cannot import from league $in_keeper_leagueName - League does not exist!</b>\n";
    close(FILE);
    $errorflag = 1;
  }
  elsif ($league->{_PASSWORD} ne "$in_keeper_leaguePassword")
  {
    open (FILE, ">>$errors");
    flock(FILE,2);
    print FILE "<b>Cannot import from league $in_keeper_leagueName - League password is incorrect!</b>($league->{_PASSWORD} vs $in_keeper_leaguePassword)\n";
    close(FILE);
    $errorflag = 1;
  }
  elsif ($league->{_DRAFT_STATUS} ne "closed")
  {
    open (FILE, ">>$errors");
    flock(FILE,2);
    print FILE "<b>Cannot import from league $in_keeper_leagueName - This league is not yet closed!</b>\n";
    close(FILE);
    $errorflag = 1;
  }
  elsif ($league->{_SPORT} ne "$in_sport")
  {
    open (FILE, ">>$errors");
    flock(FILE,2);
    print FILE "<b>Cannot import from league $in_keeper_leagueName - Incompatible sports!</b>\n";
    close(FILE);
    $errorflag = 1;
  }
  elsif ($league->{_KEEPERS_LOCKED} ne 'yes')
  {
    open (FILE, ">>$errors");
    flock(FILE,2);
    print FILE "<b>Cannot import from league $in_keeper_leagueName - The league's keepers are not locked!</b>\n";
    close(FILE);
    $errorflag = 1;
  }

  elsif ($team_conf == 0)
  {
    open (FILE, ">>$errors");
    flock(FILE,2);
    print FILE "<b>Cannot import from league $in_keeper_leagueName - You did not have a team in this league!</b>\n";
    close(FILE);
    $errorflag = 1;
  }
  
  else # Import keeper league settings here
  {
    $import_contracts = 'yes';
    $defaults{'salary_cap'} = "$league->{_SALARY_CAP}";
    $defaults{'max_members'} = "$league->{_MAX_TEAMS}";

    ## For keeper inflation percentage, need to translate to percent (ie, 1.1 => 10%)
    ($junk,$defaults{'keeper_increase'}) = split(/\./,$league->{_KEEPER_INCREASE});
    $defaults{'keeper_increase'} *= 10;
    
    ## Get fa prices for keeper possibilities
    $sth = $dbh->prepare("select position, price from fa_keepers where leagueid=$prev_leagueid");
    $sth->execute();
    while (my ($fa_pos, $fa_price) = $sth->fetchrow_array() )
    {
      $fa_prices{$fa_pos} = $fa_price;
    }
    $sth->finish();
  }
}

if ($errorflag != 1)
{
  $sport = $in_sport;
  
  $my_errors = "";
  open(FILE,"<$this_errors");
  flock(FILE,2);
  foreach $myline (<FILE>)
  {
    $my_errors = "$my_errors\n$myline";
  }
  $my_errors .= "\n";
  close(FILE);


  if ($in_draftType eq "Auction")
  {
    $auction_line1 = "Auction Salary Cap:<br>";
    $auction_line2 = "<input type=text name=salary_cap value=$defaults{'salary_cap'}><br>";
  }
  else
  {
    $auction_line1 = "";
    $auction_line2 = "";
  }

  dbDisconnect($dbh);
  print "Cache-Control: no-cache\n";
  print "Content-type: text/html\n\n";

  ## get league category data
  %cats = %{$league->{_CATEGORIES}};
  $cats_string = join('|',keys %cats);

  ## get league position data
  ##$sth = $dbh->prepare("select position from positions where league='$in_keeper_leagueName'");
  ##$sth->execute();
  ##while (my $pos = $sth->fetchrow() )
  ##{
    ##$poss{$pos} = 1;
  ##}
  ##$sth->finish();
  %poss = %{$league->{_POSITIONS}};
  $poss_string = join('|',keys %poss);



print <<HEADER;
    <HTML>
    <HEAD>
     <LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
     <TITLE>Create New League</TITLE>

     <script language="JavaScript">
     <!--

     var contracts_count=0;

     function apply_choices(keeper_status, stats, positions)
     {
       if (keeper_status != 'yes')
       {
         return true;
       }

       var my_stats = stats.split('|');
       var my_positions = positions.split('|');

       var temp;
       for(var x=0; x<my_stats.length; x++)
       {
         temp = 'league_form.' + my_stats[x] + '.checked = true';
         eval(temp)
       }

       for(var y=0; y<my_positions.length; y++)
       {
         temp = 'league_form.' + my_positions[y] + '.checked = true';
         eval(temp)
       }
       return true
     }


     function addContract(start_contracts_count)
     {
       // Only do this the FIRST time - want to increment on our own after that
       if (contracts_count == 0)
       {
         contracts_count=start_contracts_count;
       }

       // increment our row count, update the row_count form element
       contracts_count++;
       league_form.contract_count.value=contracts_count


       // Add a new row to the contracts table
       var my_table = document.getElementById('contract_table');
       var lastRow = my_table.rows.length;
       // if there's no header row in the table, then iteration = lastRow + 1
       var row = my_table.insertRow(lastRow);
       row.bgColor = "#FFFF00";
       var cell1 = row.insertCell(0);
       var textNode1 = document.createTextNode("Contract "+contracts_count);
       cell1.appendChild(textNode1);

       var cell2 = row.insertCell(1);
       var el  = document.createElement('input')
       el.type = 'text'
       el.name = 'c_min_' + contracts_count
       el.id = 'c_min_' + contracts_count
//       el.size = 4
       el.value = '0'
       cell2.appendChild(el);

       var cell3 = row.insertCell(2);
       el  = document.createElement('input')
       el.type = 'text'
       el.name = 'c_max_' + contracts_count
       el.id = 'c_max_' + contracts_count
//       el.size = 4
       el.value = '0'
       cell3.appendChild(el);

       var cell4 = row.insertCell(3);
       el  = document.createElement('input')
       el.type = 'text'
       el.name = 'c_num_' + contracts_count
       el.id = 'c_num_' + contracts_count
//       el.size = 4
       el.value = '0'
       cell4.appendChild(el);

     }
     -->
     </script>

    </HEAD>
    <BODY onLoad="apply_choices('$in_keeper','$cats_string','$poss_string')">
    <br>
    <p align=center><b>$my_errors </b></p>

HEADER
  if ($import_contracts == 'yes')
  {
print <<HEADER;
    <p align=center><b>Settings from league '$in_keeper_leagueName' are shown below<br>
    You may alter them if you wish, or simply click 'Continue' to apply them to the new league</b><br>
HEADER
  }
  else
  {
    print "<p align=center><b>Continue to Select League Configurations Below:</b><br>\n";
  }

print <<HEADER;
    <form id='league_form' action="/cgi-bin/fantasy/createNewLeague2.pl" method="post">

    <input type=hidden name="draftType" value="$in_draftType">
    <input type=hidden name="sport" value="$in_sport">
    <input type=hidden name="teamName" value="$in_teamName">
    <input type=hidden name="leagueName" value="$in_leagueName">
    <input type=hidden name="leaguePassword" value="$in_leaguePassword">
    <input type=hidden name="Keeper" value="$in_keeper">
    <input type=hidden name="keeper_leagueName" value="$in_keeper_leagueName">
    <input type=hidden name="keeper_leaguePassword" value="$in_keeper_leaguePassword">
    <input type=hidden name="keeper_name_persist" value="$in_keeper_name_persist">
    <input type=hidden name="import_contracts" value="$import_contracts">

    <table frame="box" align="center">
     <tr>
      <td colspan=2 align=center><b>Stat Categories</b></td>
      <td colspan=2 align=center><b>Additional Positions</b></td>
     </tr>
     <tr>

HEADER

  if ($sport eq 'baseball')
  {

    print <<HEADER;

      <td>
       <input type="checkbox" name="H" value="H">Hits<br>
       <input type="checkbox" name="R" value="R">Runs<br>
       <input type="checkbox" name="RBI" value="RBI">RBI<br>
       <input type="checkbox" name="ST" value="ST">Steals<br>
       <input type="checkbox" name="CS" value="CS">Caught Stealing<br>
       <input type="checkbox" name="AVG" value="AVG">Average<br>
       <input type="checkbox" name="OBP" value="OBP">OBP<br>
       <input type="checkbox" name="HR" value="HR">Home Runs<br>
       <input type="checkbox" name="TB" value="TB">Total Bases<br>
       <input type="checkbox" name="OffK" value="OffK">Strikeouts
      </td>
      <td>
       <input type="checkbox" name="IP" value="IP">Innings<br>
       <input type="checkbox" name="W" value="W">Wins<br>
       <input type="checkbox" name="L" value="L">Losses<br>
       <input type="checkbox" name="PitK" value="PitK">Strikeouts<br>
       <input type="checkbox" name="SV" value="SV">Saves<br>
       <input type="checkbox" name="CG" value="CG">Complete Games<br>
       <input type="checkbox" name="SHO" value="SHO">Shutouts<br>
       <input type="checkbox" name="ERA" value="ERA">ERA<br>
       <input type="checkbox" name="WHIP" value="WHIP">WHIP<br>
       <input type="checkbox" name="KBB" value="KBB">K/BB
      </td>
      <td>
       <input type="checkbox" name="OF2" value="OF2">OF2<br>
       <input type="checkbox" name="OF3" value="OF3">OF3<br>
       <input type="checkbox" name="Util" value="Util">Util<br>
       <input type="checkbox" name="Util2" value="Util2">Util2<br>
       <input type="checkbox" name="Util3" value="Util3">Util3<br>
       <input type="checkbox" name="Util_IN" value="Util_IN">Util IN<br>
       <input type="checkbox" name="Util_OF" value="Util_OF">Util OF<br>
       <input type="checkbox" name="SP2" value="SP2">SP2<br>
       <input type="checkbox" name="SP3" value="SP3">SP3<br>
       <input type="checkbox" name="RP2" value="RP2">RP2<br>
       <input type="checkbox" name="RP3" value="RP3">RP3<br>
      </td>
      <td>
       <input type="checkbox" name="P1" value="P1">P1<br>
       <input type="checkbox" name="P2" value="P2">P2<br>
       <input type="checkbox" name="P3" value="P3">P3<br>
       <input type="checkbox" name="B1" value="B1">B1<br>
       <input type="checkbox" name="B2" value="B2">B2<br>
       <input type="checkbox" name="B3" value="B3">B3<br>
       <input type="checkbox" name="B4" value="B4">B4<br>
       <input type="checkbox" name="B5" value="B5">B5<br>
       <input type="checkbox" name="B6" value="B6">B6<br>
       <input type="checkbox" name="B7" value="B7">B7<br>
       <input type="checkbox" name="B8" value="B8">B8<br>
       <input type="checkbox" name="B9" value="B9">B9<br>
      </td>
     </tr>
    
     <tr>
      <td colspan=4 align=center>
       <b>Misc. Info</b>
      </td>
     </tr>
     <tr>
      <td colspan=2 align=center>
       Max League Members:<br>
       $auction_line1
      </td>
      <td colspan=2>
       <input type="text" name="max_members" value="$defaults{'max_members'}"><br>
       $auction_line2
      </td>
     </tr>
HEADER

    
  }
  
  elsif ($sport eq 'football')
  {
print <<HEADER;

     <td>
      <input type="checkbox" name="PassTD" value="PassTD">Pass TD<br>
      <input type="checkbox" name="PassY" value="PassY">Pass Yards<br>
      <input type="checkbox" name="OINT" value="OINT">Off. Interceptions<br>
      <input type="checkbox" name="RunTD" value="RunTD">Rush TD <br>
      <input type="checkbox" name="RunY" value="RunY">Rush Yards<br>
      <input type="checkbox" name="RecTD" value="RecTD">Rec TD<br>
      <input type="checkbox" name="RecY" value="RecY">Rec Yards<br>
      <input type="checkbox" name="Rec" value="Rec">Receptions<br>
      <input type="checkbox" name="RetTD" value="RetTD">Return TDs<br>
      <input type="checkbox" name="RetY" value="RetY">Return Yards<br>
      <input type="checkbox" name="FG" value="FG">Field Goals<br>
      <input type="checkbox" name="FGmiss" value="FGmiss">FG missed<br>
     </td>
     <td>
      <input type="checkbox" name="XP" value="XP">Extra Points<br>
      <input type="checkbox" name="XPmiss" value="XPmiss">Extra Points Missed<br>
      <input type="checkbox" name="TwoP" value="TwoP">2-Point Conv<br>
      <input type="checkbox" name="Fum" value="Fum">Fumbles<br>
      <input type="checkbox" name="Sack" value="Sack">Sacks<br>
      <input type="checkbox" name="DINT" value="DINT">Def Interceptions<br>
      <input type="checkbox" name="FumRec" value="FumRec">Fumble Recovery<br>
      <input type="checkbox" name="DefTD" value="DefTD">Def TD<br>
      <input type="checkbox" name="Safe" value="Safe">Safety<br>
      <input type="checkbox" name="Block" value="Block">Blocked Kick<br>
      <input type="checkbox" name="PtsAll" value="PtsAll">Points Allowed<br>
      <input type="checkbox" name="Pen" value="Pen">Penalty Yards      
     </td>
     <td>
      <input type="checkbox" name="RB2" value="RB2">RB2<br>
      <input type="checkbox" name="RB3" value="RB3">RB3<br>
      <input type="checkbox" name="WR2" value="WR2">WR2<br>
      <input type="checkbox" name="WR3" value="WR3">WR3<br>
      <input type="checkbox" name="OFF1" value="OFF1">OFF1<br>
      <input type="checkbox" name="OFF2" value="OFF2">OFF2<br>
      <input type="checkbox" name="QB2" value="QB2">QB2<br>
      <input type="checkbox" name="QB3" value="QB3">QB3<br>
      <input type="checkbox" name="K2" value="K2">K2<br>
      <input type="checkbox" name="TE2" value="TE2">TE2<br>
      <input type="checkbox" name="DEF2" value="DEF2">DEF2<br>
     </td>
     <td>
      <input type="checkbox" name="B1" value="B1">B1<br>
      <input type="checkbox" name="B2" value="B2">B2<br>
      <input type="checkbox" name="B3" value="B3">B3<br>
      <input type="checkbox" name="B4" value="B4">B4<br>
      <input type="checkbox" name="B5" value="B5">B5<br>
      <input type="checkbox" name="B6" value="B6">B6<br>
      <input type="checkbox" name="B7" value="B7">B7<br>
      <input type="checkbox" name="B8" value="B8">B8<br>
      <input type="checkbox" name="B9" value="B9">B9<br>
     </td>
    </tr>   
    <tr>
     <td colspan=4 align=center>
      <b>Misc. Info</b>
     </td>
    </tr>
    <tr>
     <td colspan=2>
       Max League Members:<br>
       $auction_line1
      </td>
      <td colspan=2>
       <input type="text" name="max_members" value="$defaults{'max_members'}"><br>
       $auction_line2
      </td>
     </tr>

HEADER

  }

  if ($in_keeper eq 'yes')
  {


print <<HEADER;
     <tr>
      <td colspan=4 align=center>
       <b>Keeper Info</b>
      </td>
     </tr>
     <tr>
       <td colspan=4>
        <table name='contract_table' id='contract_table'>
          <tr>
            <td align=center>Contract Name</td>
            <td align=center>Min Years</td>
            <td align=center>Max Years</td>
            <td align=center>Number of Contracts</td>
          </tr>

HEADER

    my $sth_contracts = $dbh->prepare("select min, max, number from keeper_slots where leagueid=$prev_leagueid");
    $sth_contracts->execute();
    while (my ($min,$max,$num) = $sth_contracts->fetchrow_array() )
    {
      $con_count++;

print <<HEADER;

         <tr>
          <td>
           Contract $con_count</td>
          <td>
           <input type="text" name="c_min_${con_count}" value="$min">
          </td>
          <td>
           <input type="text" name="c_max_${con_count}" value="$max">
          </td>
          <td>
           <input type="text" name="c_num_${con_count}" value="$num">
          </td>
         </tr>

HEADER

    }
    $sth_contracts->finish();


print <<HEADER;
        </table>
      </td>
     </tr>
     <tr>
       <td colspan=4 align="middle">
        <a href="javascript:addContract($con_count)"><font color='blue'>Add new contract option</font></a>
       </td>
     </tr>
     <tr>
      <td colspan=2>
       Keeper Increase (Percent; 10 = 10% price increase per year)</td>
      <td colspan=2>
       <input type="text" name="keeper_increase" value="$defaults{'keeper_increase'}"></td>
     </tr>

HEADER


    foreach my $fa_pos (sort keys %fa_prices)
    {

print <<HEADER;
     <tr>
      <td colspan=2>
       FA/Waiver <b>$fa_pos</b> Price (Initial price for undrafted keeper $fa_pos)</td>
      <td colspan=2>
       <input type="text" name="${fa_pos}_price" value="$fa_prices{$fa_pos}"></td>
     </tr>

HEADER

    }
  }

print <<HEADER;

    </table>
    <br><br>
 
    <p align="center">
     <input type=hidden name="contract_count" value="$con_count">
     <input type="submit" value="Continue">
     <input type="reset" value="Clear Form"> 
    </p>
   </p>
   </form>

   </BODY>
   </HTML>

HEADER

}
else
{
  dbDisconnect($dbh);
  print "Location: $return\n\n";
}
