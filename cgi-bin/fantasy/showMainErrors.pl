#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use Session;
use CGI::Cookie;

$error1 = "/var/log/fantasy/create_league_errors1.txt";
$error2 = "/var/log/fantasy/create_league_errors2.txt";
$error3 = "/var/log/fantasy/join_league_errors.txt";

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();

print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";

print <<EOM;
<html>
 <head>
  <LINK REL=StyleSheet HREF="/fantasy/style.css" TYPE="text/css" MEDIA=screen>
 </head>
 <body>
  <p align=center>
EOM

open (ERROR,"<$error1");
flock(ERROR,2);
@LINES=<ERROR>;
chomp (@LINES);
close(ERROR);
$SIZE=@LINES;

open(ERROR,">$error1");
flock(ERROR,2);
for($x=0;$x<$SIZE;$x++)
{
  ($id,$name,$message) = split(';',$LINES[$x]);
  if (($userAddr eq $ip) | ($name eq $user))
  {
print <<EOM;
   $message<br>
EOM
  }
  else
  {
    print ERROR "$LINES[$x]\n";
  }
}
close(ERROR);


open (ERROR2,"<$error2");
flock(ERROR2,1);
@LINES=<ERROR2>;
chomp (@LINES);
close(ERROR2);
$SIZE=@LINES;

open(ERROR2,">$error2");
flock(ERROR2,2);
for($x=0;$x<$SIZE;$x++)
{
  ($id,$name,$message) = split(';',$LINES[$x]);
  if (($userAddr eq $ip) | ($name eq $user))
  {
print <<EOM;
   $message<br>
EOM
  }
  else
  {
    print ERROR2 "$LINES[$x]\n";
  }
}
close(ERROR2);


open (ERROR3,"<$error3");
flock(ERROR3,1);
@LINES=<ERROR3>;
chomp (@LINES);
close(ERROR3);
$SIZE=@LINES;

open(ERROR3,">$error3");
flock(ERROR3,2);
for($x=0;$x<$SIZE;$x++)
{
  ($id,$name,$message) = split(';',$LINES[$x]);
  if (($userAddr eq $ip) | ($name eq $user))
  {
print <<EOM;
   $message<br>
EOM
  }
  else
  {
    print ERROR3 "$LINES[$x]\n";
  }
}
close(ERROR3);

print <<EOM;
</p>
</body>
</html>

EOM
