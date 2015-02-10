#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use CGI;
use CGI  qw/:standard/;
use CGI::Cookie;
use DBI;
use Session;
use DBTools;

my $cgi = new CGI;

#variables that will be used later.

$return = '/cgi-bin/fantasy/getTeam.pl';

open (FILE, ">$errors");
 flock(FILE,2);
 print FILE "\n";
close(FILE);

## Input stuff
my $user = $cgi->param('NAME');
my $passwd = $cgi->param('PASSWORD');
my $email = $cgi->param('EMAIL');
my $check_pwd = $cgi->param('PASSWORD_CHECK');
$expire = "+1d";
$expire = '' if($cgi->param('public'));
$id = '';
my $error = 0;

if ((! defined $user) || (! defined $passwd) || (! defined $email)
     || ($user =~ /^\s*$/) || ($email =~ /^\s*$/))
{
  $error = 1;
}

   $dbh = dbConnect();

   ## Connect to password database
   my $table = "passwd";
   my $sth = $dbh->prepare("SELECT * FROM $table WHERE name = '$user'")
          or die "Cannot prepare: " . $dbh->errstr();
   $sth->execute() or die "Cannot execute: " . $sth->errstr();
   ($owner,$pwd_check,$mail) = $sth->fetchrow_array();

    
   $sth->finish();

   if($check_pwd ne $passwd || $owner ne '')
   {
     $error=1;
   }
   elsif ($error != 1)
   {
     $userAddr = $ENV{REMOTE_ADDR};
     $sth = $dbh->prepare("INSERT INTO passwd (name,passwd,email) VALUES ('$user','$passwd','$email')")
            or die "Cannot prepare: " . $dbh->errstr();
     $sth->execute() or die "Cannot execute: " . $sth->errstr();

     while(!$id)
     {
       $id = int(rand(10000));
       $sth = $dbh->prepare("SELECT owner, IP FROM sessions WHERE sess_id = '$id'")
            or die "Cannot prepare: " . $dbh->errstr();
       $sth->execute() or die "Cannot execute: " . $sth->errstr();
       my ($user, $ip) = $sth->fetchrow_array();
       $sth->finish();
       $id = '' if($user);
     }

     $sth = $dbh->prepare("INSERT INTO sessions (IP,password,owner,sess_id) VALUES ('$ENV{REMOTE_ADDR}','$passwd','$user','$id')")
            or die "Cannot prepare: " . $dbh->errstr();
     $sth->execute() or die "Cannot execute: " . $sth->errstr();
     $sth->finish();   

     my $cookie = new CGI::Cookie(-name=>'SESS_ID',-value=>$id,-expires=>"$expire");
     # Baking cookie sets headers
     print "Set-cookie: $cookie\n";

     $return = '/fantasy/fantasy_main_index.htm';
   }

   dbDisconnect($dbh);
 

print "Status: 302 Moved\nLocation: $return\n\n";