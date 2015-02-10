#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use DBI;

my $cgi = new CGI;

my $user = $cgi->param('user');
my $passwd = $cgi->param('passwd');
my $expire = "+1d";
$expire = '' if($cgi->param('public'));
my $id = '';

#get user
my $table = "sessions";
my $dbh = DBI->connect("DBI:mysql:doncote_draft:localhost","doncote_draft","draft")
               or die "Couldn't connect to database: " .  DBI->errstr;
my $sth = $dbh->prepare("SELECT passwd FROM $table WHERE user = '$user'")
       or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
my $pwd_check = $sth->fetchrow_array();
$sth->finish();

if($pwd_check eq $passwd)
{
    while(!$id)
    {
        $id = int(rand(10000));
        $sth = $dbh->prepare("SELECT user FROM session WHERE sess_id = '$id'")
              or die "Cannot prepare: " . $dbh->errstr();
        $sth->execute() or die "Cannot execute: " . $sth->errstr();
        my $test = $sth->fetchrow_array();
        $sth->finish();
        $id = '' if($test);
    }
    $sth = $dbh->prepare("INSERT INTO session (sess_id,user,ip) VALUES ('$id','$user','$ENV{REMOTE_ADDR}')")
           or die "Cannot prepare: " . $dbh->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    $sth->finish();   
    
    my $cookie = new CGI::Cookie(-name=>'SESS_ID',-value=>$id,-expires=>"$expire");
      #$cookie->bake;    
      print "Set-cookie: $cookie\n";
}
print "Status: 302 Moved\nLocation: $ENV{HTTP_REFERER}\n\n";
#print "test next line. cookie set?";

$dbh->disconnect();

