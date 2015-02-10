#!/usr/bin/perl
use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use Session;
use DBTools;

my $cgi = new CGI;


#variables that will be used later.
$return = "/cgi-bin/fantasy/getBoard.pl"; 
$errors = "./error_logs/board_errors.txt";
$team_error_file = './error_logs/team_errors.txt';
$errorflag=0;


#time stuff.
($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);

#24-hour scheme
$hour_tf = $Hour;
$daymins = (60 * $hour_tf) + $Minute;

my $RealMonth = $Month + 1;
if($RealMonth < 10)
{
   $RealMonth = "0" . $RealMonth; 
}
if($Day < 10)
{
   $Day = "0" . $Day; # add a leading zero to one-digit days
}
$Fixed_Year = $Year + 1900;
$time_string = "AM";
if($Hour >= 12)
{
   $Hour = $Hour % 12;
   $time_string = "PM";
}
if($Hour == 0)
{
   $Hour = 12;
}
if($Minute < 10)
{
   $Minute = "0" . $Minute; # add a leading zero to one-digit days
}

  open (FILE, ">$errors");
  flock(FILE,2);
  print FILE "\n";
  close(FILE);

## Input Variables
$in_TEAMS = $cgi->param('TEAMS');
$in_TEAM_PASSWORD = $cgi->param('TEAM_PASSWORD');
$in_message = $cgi->param('message');


my ($my_ip,$namer,$pswd,$my_id,$team_t,$sport_t,$league_t) = checkSession();
my $dbh = dbConnect();

#Get League Data
$sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_start_time,$auction_end_time,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
$sth->finish();


# If we are not using the IP address to find the user name, overwrite the user name with the one that was provided
if ($use_IP_flag eq 'no')
{
  if ($in_TEAMS eq "Select A Team")
  {
    open (FILE, ">>$errors");
     flock(FILE,2);
     print FILE "<b>You must select a Team Name!</b>\n";
    close(FILE);
    $errorflag = 1;
  }
  else 
  {

    ## Connect to password database
    my $table = "passwd";
    $owner = '';
    $sth = $dbh->prepare("SELECT * FROM $table WHERE name = '$in_TEAMS' AND passwd = '$in_TEAM_PASSWORD'")
            or die "Cannot prepare: " . $dbh->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    ($owner,$password,$email) = $sth->fetchrow_array();
    $sth->finish();

    if($owner ne $in_TEAMS)
    {
      $errorflag=1;
      $return = "http://www.gunslingersultimate.com/cgi-bin/fantasy/getBids.pl";
      open (FILE,">>$error_file"); 
       flock(FILE,2);
       print FILE "<b>Your Password is Incorrect!</b>\n";
      close(FILE);
    }
  }
}

$messagereal = "./text_files/message_board_$league_t.txt";

if ($errorflag != 1){
  $message = $in_message;
  $message =~ s/\r\n/\<br>/g;

  open (FILE,">$errors");
  flock(FILE,2);
  print FILE "\n";
  close(FILE);
  
  $printed_hour = $Hour + $TZ_offset;
  if (($printed_hour >= 12) && ($printed_hour < 24))
  {
    $time_string = 'PM';
  }
  else
  {
    $time_string = 'AM';
  }

  $printed_hour = $printed_hour%12;

  if ($printed_hour == 0)
  {
    $printed_hour = 12;
  }

  open (MSG,">>$messagereal");
  flock(MSG,2);
     print MSG "$in_TEAMS;";
     print MSG "$RealMonth/$Day/$Fixed_Year ($printed_hour:$Minute $time_string);";
     print MSG "$message\n";
  close (MSG);
}

dbDisconnect($dbh);
print "Location: $return\n\n";
