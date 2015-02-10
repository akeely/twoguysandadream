#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use DBTools;
use Session;

my $cgi = new CGI;

#variables that will be used later.
$in_team_name = $cgi->param('teamName');
$in_league_password = $cgi->param('leaguePassword');
$in_league_name = $cgi->param('leagueName');


$return = "/fantasy/fantasy_main_index.htm";
$errors = "/var/log/fantasy/join_league_errors.txt";
$errorflag = 0;

open (FILE,">$errors");
 flock(FILE,1);
 print FILE " ";
close(FILE);


my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t)  = checkSession();
my $dbh = dbConnect();

## Make sure that the owner has entered a league name
if ($in_league_name =~ /^$/)
{
  open (FILE,">>$errors");
  flock(FILE,2);
  print FILE "$ip;$user;<b>Please Enter a League Name!</b>\n";
  close(FILE);
  $errorflag = 1;
}

## Make sure that the owner has entered a league password
if ($in_league_password =~ /^$/)
{
  open (FILE,">>$errors");
  flock(FILE,2);
  print FILE "$ip;$user;<b>Please Enter a League Password!</b>\n";
  close(FILE);
  $errorflag = 1;
}

## Make sure that the owner has entered a team name
if ($in_team_name =~ /^$/)
{
  open (FILE,">>$errors");
  flock(FILE,2);
  print FILE "$ip;$user;<b>Please Enter a Team Name!</b>\n";
  close(FILE);
  $errorflag = 1;
}

if ($errorflag != 1)
{

  #Get League Data
  $sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$in_league_name'")
           or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  $league_name = 'blank';
  ($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
  $sth->finish();

  if($password ne $in_league_password)
  {
    $errorflag=1;
    open (FILE,">>$errors");
     flock(FILE,2);
     print FILE "$ip;$user;<b>Your League Password is Incorrect!</b>\n";
    close(FILE);
  }
  elsif($draftStatus eq 'closed')
  {
    $errorflag=1;
    open (FILE,">>$errors");
     flock(FILE,2);
     print FILE "$ip;$user;<b>The draft for this league has already finished!</b>\n";
    close(FILE);
  }
  elsif ($league_name eq 'blank')
  {
    $errorflag=1;
    open (FILE,">>$errors");
     flock(FILE,1);
     print FILE "$ip;$user;<b>Your have entered an invalid League Name!</b>\n";
    close(FILE);
  }
  elsif (length($in_team_name) > 18)
  {
    $errorflag=1;
    open (FILE,">>$errors");
     flock(FILE,1);
     print FILE "$ip;$user;<b>Your Team Name can only be 18 characters long!</b>\n";
    close(FILE);
  }
  else
  {
    #password for valid league name was accepted
    $found = 1;
    $count = 0;

    $sth = $dbh->prepare("SELECT count(*) FROM teams WHERE league = '$in_league_name' AND owner = '$user'")
         or die "Cannot prepare: " . $dbh->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();

    $count = $sth->fetchrow_array();
    $sth->finish();
    if ($count != 0)
    {
      $errorflag=1;
      open (FILE,">>$errors");
       flock(FILE,2);
       print FILE "$ip;$user;<b>You can only have one team in this league!</b>\n";
      close(FILE);
    }

    $sth = $dbh->prepare("SELECT count(*) FROM teams WHERE league = '$in_league_name' AND name = '$in_team_name'")
         or die "Cannot prepare: " . $dbh->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();

    $count = $sth->fetchrow_array();
    $sth->finish();
    if ($count != 0)
    {
      $errorflag=1;
      open (FILE,">>$errors");
       flock(FILE,2);
       print FILE "$ip;$user;<b>There is already an owner in this league with the team name $in_team_name!</b>\n";
      close(FILE);
    }

    if ($errorflag != 1)
    {
      # Add team to teams db if name is original and is owner's sole occurance
      $sth = $dbh->prepare("INSERT INTO teams VALUES('$user','$in_team_name','$in_league_name','0','$sport',0)") or die "Cannot prepare: " . $dbh->errstr();
      $sth->execute() or die "Cannot execute: " . $sth->errstr();
      $sth->finish();
      
      ##
      ## PRINT in Error File that user has joined the league!!??
      ##
      open (FILE,">>$errors");
       flock(FILE,1);
       print FILE "$ip;$user;<b>$in_team_name has been added to league $in_league_name!</b>\n";
      close(FILE);

    }
  }
}


dbDisconnect($dbh);
print "Location: $return\n\n";
