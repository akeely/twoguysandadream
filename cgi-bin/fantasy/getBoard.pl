#!/usr/bin/perl
use CGI;
use CGI::Cookie;
use DBTools;
use Session;

# script to generate an message board page

# files
$add_error_file = './error_logs/add_errors.txt';
$board_error_file = './error_logs/board_errors.txt';
$team_error_file = "./error_logs/team_errors.txt";


########################
#
# Header1 Print
#
########################

sub Header1()
{

print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";

print <<HEADER1;

<HTML>
<HEAD>
<TITLE>Message Board Page</TITLE>

<script language="JavaScript">
<!--
function pswd_checker()
{


  if (msg_form.message.value == '')
  {
    alert("Your message must not be empty")
    return (false);
  }

  if (msg_form.TEAM_PASSWORD.value == '')
  {
    alert("Please enter a password")
    return (false);
  }

  if (msg_form.TEAMS.value == 'Select A Team')
  {
    alert("Please select a Team")
    return (false);
  }

  return (true);
}
-->
</script>


<LINK REL=StyleSheet HREF="http://www.gunslingersultimate.com/fantasy/style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<h2 align=center><u>Welcome to the Message Board!</u></h2>

<p align=center><a href="http://www.gunslingersultimate.com/fantasy/fantasy_main_index.htm">Fantasy Home</a>
<br>

<iframe src="http://www.gunslingersultimate.com/fantasy/nav.htm" width="100%" height="60" scrollbars="no" frameborder="0"></iframe>

HEADER1

}

########################
#
# Header1.1 Print
#
########################

sub Header11()
{

print <<HEADER11;

</p>

<p align=center>Click to see the <A href="http://www.gunslingersultimate.com/fantasy/rules.htm" target="rules">rules</a>.


HEADER11

}


########################
#
# Header2 Print
#
########################

sub Header2($)
{

 my $namer = shift;

print <<HEADER2;

<form name="msg_form" method="post" action="http://www.gunslingersultimate.com/cgi-bin/fantasy/putBoard.pl">

<p align="center">Team: <b>$namer</b> - Add your message here:<br>
<textarea name="message" rows="6" cols="45" wrap="virtual" align="center"></textarea>

<br>

<p align = "center">

HEADER2

}


########################
#
# Header2.1 Print
#
########################

sub Header21()
{

print <<HEADER2;

<form name="msg_form" method="post" action="http://www.gunslingersultimate.com/cgi-bin/fantasy/putBoard.pl" onsubmit="return pswd_checker()">

<p align="center">Add your message here:<br>
<textarea name="message" rows="6" cols="45" wrap="virtual" align="center"></textarea>

<br>

<p align = "center">

HEADER2

}


####################
#
# Header3 Print
#
####################

sub Header3($$)
{
  my $league = shift;
  my $myteam = shift;

  if ($use_IP_flag eq 'no')
  {
    print <<HEADER3;

    <br>
    <table>
     <tr>
      <td align=middle>User Name</td>
      <td align=middle>Password</td>
     </tr>
     <tr>
      <td align=middle> 
       <select name="TEAMS">

HEADER3
   
   ## Output each team name as an option in the pull-down - default to cookie team name if available
   # Connect to DB
   $dbh = dbConnect();

   #Get Team List
   $sth = $dbh->prepare("SELECT * FROM teams WHERE league = '$league'")
        or die "Cannot prepare: " . $dbh->errstr();
   $sth->execute() or die "Cannot execute: " . $sth->errstr();

   while (($tf_owner, $tf_name, $tf_league, $tf_adds) = $sth->fetchrow_array())
   {
     $check = "";
     if ($tf_name eq $myteam)
     {
        $check = "selected";
     }

     PrintOwner($tf_owner,$tf_name,$check);
   }
   
   $sth->finish();
   dbDisconnect($dbh);


print <<HEADER3;

        </select>
      </td>
      <td align=middle>
        <input type="password" name="TEAM_PASSWORD">
      </td>
     </tr>
    </table>
    <br>   

HEADER3

  } # end if($use_IP_flag)
  else
  {

print <<HEADER3;

<input type="hidden" name="TEAMS" value="$myteam">

HEADER3

  }

print <<HEADER3;
         

<input type="submit" value="Submit My Message!" id=submit1 name=submit1>
<input type="reset" value="Clear The Forms" id=reset1 name=reset1> 
<br><input type="checkbox" name="show_all">Show Auction Alerts
<br>Please, only hit submit <b>once</b><br>

<b>Previous Posts:</b><br><br>
<hr width = 65%>


</form>
</p> 

HEADER3

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

######################
#
# Add Player
#
######################


sub AddEntry($$$)
{
	my $team = shift;
	my $timer = shift;
	my $entry = shift;

print <<EOM;

<p align="center"><b>Posted by:</b> $team at $timer:<br>
$entry<br><br><hr width = 65%></p>


EOM

}

######################
#
# Print Owner
#
######################


sub PrintOwner($$$)
{
  my $owner = shift;
  my $team  = shift;
  my $check = shift;

print <<EOM;

  <option value="$owner" $check> 
  $team

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

$message<br>

EOM

}

##############
#
# Main Function
#
##############

# variables for players
my $team;
my $timer;
my $entry;
my $owner;
my $password;

my ($my_ip,$namer,$pswd,$my_id,$team_t,$sport_t,$league_t) = checkSession();
my $dbh = dbConnect();

#Get League Data
$sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_start_time,$auction_end_time,$auction_length,$bid_time_extension, $bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
$sth->finish();


if ($use_IP_flag eq 'yes')
{
    Header1();
    Header11();
    Header2($namer);

    open(MESSAGES, "<$board_error_file");
    flock(MESSAGES,2);
    @LINES=<MESSAGES>;
    chomp (@LINES);
    close(MESSAGES);
    $SIZE=@LINES;

   for($m=0;$m<$SIZE;$m++)
   {
     ListError($LINES[$m]);
   }

   Header3($league_t,$team_t);

   $message_file = "./text_files/message_board_$league_t.txt";
   open(MESSAGES, "<$message_file");
    flock(MESSAGES,2);
    @LINES=<MESSAGES>;
    chomp (@LINES);
    close(MESSAGES);
    $SIZE=@LINES;
   
   for ($n=$SIZE-1; $n>=0; $n--)
   {
        $line=@LINES[$n];
        if ($line !~ /AUCTION ALERT/)
  	{
          ($team,$timer,$entry) = split(';', $line);
	  AddEntry($team,$timer,$entry);
        }
   }

   Footer();
}

else #if not using IP Addresses to ID users
{
  Header1();
  Header11();
  Header21();

  open(MESSAGES, "<$board_error_file");
   flock(MESSAGES,2);
   @LINES=<MESSAGES>;
  chomp (@LINES);
   close(MESSAGES);
   $SIZE=@LINES;

  for($m=0;$m<$SIZE;$m++){
    ListError($LINES[$m]);
  }

  Header3($league_t,$namer);

  $message_file = "./text_files/message_board_$league_t.txt";
  open(MESSAGES, "<$message_file");
   flock(MESSAGES,2);
   @LINES=<MESSAGES>;
   chomp (@LINES);
  close(MESSAGES);
  $SIZE=@LINES;

  for ($n=$SIZE-1; $n>=0; $n--)
  {
         $line=@LINES[$n];
        if ($line !~ /AUCTION ALERT/)
  	{
          ($team,$timer,$entry) = split(';', $line);
	  AddEntry($team,$timer,$entry);
        }
  }

  Footer();

}

dbDisconnect($dbh);
