#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;

use Session;
use DBTools;

my $cgi = new CGI;

#variables that will be used later.
$return = "/cgi-bin/fantasy/teamHome.pl"; 
$errors = "/var/log/fantasy/home_errors.txt";
$team_error_file = "/var/log/fantasy/team_errors.txt";
$errorflag=0;

# Get Global Variables
$global_file = "/var/log/fantasy/global_vars.txt";
open(GLOBALS,"<$global_file");
flock(GLOBALS,1);
@GLINES=<GLOBALS>;
chop(@GLINES);
close(GLOBALS);
$global_vars = $GLINES[1];
($auction_start_time,$auction_end_time,$auction_length,$bid_time_extension, $bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag, $password_file,$code_file,$sessions,$leagues,$team_file) = split(';',$global_vars);

open (FILE, ">$errors");
 flock(FILE,2);
 print FILE "\n";
close(FILE);

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) = checkSession();


$player = $cgi->param('name');
$limit = $cgi->param('limit');

if($cgi->param('auto')){
   $auto = $cgi->param('auto');
}
else {
   $auto = "no";
}

open (FILE,">$errors");
flock(FILE,2);
print FILE "";
close(FILE);

open (TEMP,"<$targets");
flock(TEMP,1);
@TEMP_LINES=<TEMP>;
chop (@TEMP_LINES);
close(TEMP);
$TEMP_SIZE=@TEMP_LINES;

open (TEMP,">$targets");
flock(TEMP,2);

$add_player = 1;  #flag for whether the player must be appended to the list
foreach $myline(@TEMP_LINES)
{
    ($id_t,$player_t,$limit_t,$auto_t)=split(';',$myline);
    if (($id_t eq $user) & ($player_t eq $player))
    {
        $auto_t = $auto;
        $add_player = 0;
    }
    print TEMP "$id_t;$player_t;$limit_t;$auto_t\n";
}

if ($add_player == 1)
{
    print TEMP "$user;$player;$limit;$auto\n";
}
close(TEMP);

print "Location: $return\n\n";
