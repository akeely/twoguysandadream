#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI  qw/:standard/;
use CGI::Cookie;
use DBTools;

my $cgi = new CGI;

#variables that will be used later.

$return = '/cgi-bin/fantasy/getTeam.pl';
$bid_errors = "/var/log/fantasy/bid_errors.txt";
$errors = "/var/log/fantasy/team_errors.txt";
$errorflag = 0;

open (FILE, ">$errors");
 flock(FILE,2);
 print FILE "\n";
close(FILE);

## Input stuff
my $user = $cgi->param('TEAMS');
my $passwd = $cgi->param('TEAM_PASSWORD');
$expire = "+1d";
$expire = '' if($cgi->param('public'));
$id = '';

## Make sure that the owner has selected a team name
if ($user eq "Select Your Team")
{
  open (FILE,">>$errors");
  flock(FILE,2);
  print FILE "<b>Please Select a Team Name!</b>\n";
  close(FILE);
  $errorflag = 1;
}

## CHECK PASSWORD ## 
if ($errorflag != 1)
{
 if ($passwd =~ /^$/)
 {
    open (FILE, ">>$errors");
    flock(FILE,2);
    print FILE "<b>The password field must be filled out to properly submit this form!</b>\n";
    close(FILE);
    $errorflag = 1;
 }
 else
 {
   $dbh = dbConnect();

   ## Connect to password database
   my $table = "passwd";
   my $sth = $dbh->prepare("SELECT * FROM $table WHERE name = '$user'")
          or die "Cannot prepare: " . $dbh->errstr();
   $sth->execute() or die "Cannot execute: " . $sth->errstr();
   ($owner,$pwd_check,$mail) = $sth->fetchrow_array();

   $sth->finish();

   if($pwd_check ne $passwd)
   {
     $errorflag=1;
     open (FILE,">>$errors");
     flock(FILE,2);
     print FILE "<b>Your Password is Incorrect!</b>\n";
     close(FILE);
   }
   else
   {
     $userAddr = $ENV{REMOTE_ADDR};

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

     $sth = $dbh->prepare("REPLACE INTO sessions (IP,password,owner,sess_id) VALUES ('$ENV{REMOTE_ADDR}','$passwd','$user','$id')")
            or die "Cannot prepare: " . $dbh->errstr();
     $sth->execute() or die "Cannot execute: " . $sth->errstr();
     $sth->finish();   

     my $cookie = new CGI::Cookie(-name=>'SESS_ID',-value=>$id,-expires=>"$expire");
     # Baking cookie sets headers
     print "Set-cookie: $cookie\n";

     $return = '/fantasy/fantasy_main_index.htm';
   }

   dbDisconnect($dbh);
 }
}


print "Status: 302 Moved\nLocation: $return\n\n";
