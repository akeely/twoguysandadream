#!/usr/bin/perl
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;

print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";

$error1 = "./error_logs/create_league_errors1.txt";
$error2 = "./error_logs/create_league_errors2.txt";
$error3 = "./error_logs/join_league_errors.txt";
$userAddr = $ENV{REMOTE_ADDR};

# find out the name of the session user
my $query = new CGI;
my $cookie = "SESS_ID";
my $id = $query->cookie(-name => "$cookie");
my $ip = "";
my $userAddr = $ENV{REMOTE_ADDR};

# If the cookie is valid, get the IP that the session is for
if($id){
  $dbh = DBI->connect("DBI:mysql:doncote_draft:localhost","doncote_draft","draft")
                or die "Couldn't connect to database: " .  DBI->errstr;
  $sth = $dbh->prepare("SELECT * FROM sessions WHERE sess_id = '$id'")
        or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
      ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = $sth->fetchrow_array();
  $sth->finish();
  $dbh->disconnect();
}


print <<EOM;
<html>
 <head>
  <LINK REL=StyleSheet HREF="http://www.zwermp.com/cgi-bin/fantasy/style.css" TYPE="text/css" MEDIA=screen>
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

