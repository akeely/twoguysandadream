#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
my $cgi = new CGI;
use DBTools;
use Session;

#variables that will be used later.
$return = "/cgi-bin/fantasy/teamHome.pl"; 
$errors = "/var/log/fantasy/home_errors.txt";
$team_error_file = "/var/log/fantasy/team_errors.txt";
$errorflag=0;

open (FILE, ">$errors");
 flock(FILE,1);
 print FILE "\n";
close(FILE);

if ($cgi->param('name0') =~ /^$/)
{
    open (FILE, ">>$team_error_file");
    flock(FILE,2);
    print FILE "<b>You must select a player!</b>\n";
    close(FILE);
    $errorflag = 1;
    $return = "/cgi-bin/fantasy/teamHome.pl";
}


my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) = checkSession();


for ($x=0;$x<=$cgi->param('total');$x++)
{
  $player = $cgi->param("name$x");
  $limit = $cgi->param("limit$x");

  if($cgi->param("auto$x")){
     $auto = "yes";
  }
  else {
     $auto = "no";
  }

  open (FILE,">$errors");
  flock(FILE,2);
  print FILE "";
  close(FILE);

  $targets = "/var/log/fantasy/player_targets_$league_t.txt";
     open (TEMP,"<$targets");
     flock(TEMP,1);
     @TEMP_LINES=<TEMP>;
     chop (@TEMP_LINES);
     close(TEMP);
     $TEMP_SIZE=@TEMP_LINES;

     open (TEMP,">$targets");
     flock(TEMP,1);

     $add_player = 1;  #flag for whether the player must be appended to the list

     foreach $myline(@TEMP_LINES)
     {
         ($team2,$player2,$limit2,$auto2)=split(';',$myline);
         if (($team_t eq $team2) & ($player2 eq $player))
         {
	   $limit2 = $limit;
	   $auto2 = $auto;
           $add_player = 0;
         }

         if ($limit2 > 0)
	 {
	   print TEMP "$team2;$player2;$limit2;$auto2\n";
         }
     }

     if (($add_player == 1) && ($limit > 0))
     {
	 print TEMP "$team_t;$player;$limit;$auto\n";
     }
     close(TEMP);
}

print "Location: $return\n\n";
