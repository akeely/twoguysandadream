package Session;

use strict;

use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use DBTools;
require Exporter;
our @ISA = qw(Exporter);
use vars qw/@EXPORT/;
@EXPORT = qw/checkSession/;


my $errors = "/var/log/fantasy/home_errors.txt";
my $team_error_file = "/var/log/fantasy/team_errors.txt";
my $login_url = "/cgi-bin/fantasy/getTeam.pl";

sub checkSession() {

    my $cookie = "SESS_ID";
    my $query = new CGI;
    my $id = $query->cookie(-name => "$cookie");
    my $ip = "";
    my @values;
    # If the cookie is valid, get the IP that the session is for
    if($id){
      my $dbh = dbConnect();
      my $sth = $dbh->prepare("SELECT s.ip, s.sess_id, s.sport, s.leagueid, s.teamid, s.ownerid, p.name, t.name FROM sessions s JOIN passwd p ON p.id=s.ownerid LEFT JOIN teams t ON t.id=s.teamid WHERE sess_id = '$id'")
            or die "Cannot prepare: " . $dbh->errstr();
      $sth->execute() or die "Cannot execute: " . $sth->errstr();
      @values = $sth->fetchrow_array();
      $ip = $values[0];
      dbDisconnect($dbh);
    }
    
 
    # If the session is from a different IP, force the user to sign in
    if (($ip ne $ENV{REMOTE_ADDR}) | (!$id))
    {
      open(TEAM,">$team_error_file");
      flock(TEAM,2);
      print TEAM "<b>You must login!</b>\n";
      close(TEAM);
    
      print "Location: $login_url\n\n";
   
      exit;
    }
  
    return @values;
}

1;
