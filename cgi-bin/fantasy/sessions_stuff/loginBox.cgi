#!/usr/bin/perl

#use CGI;
#use DBI;
#use CGI::Carp qw(fatalsToBrowser);
#use CGI::Cookie;

#get existing session
#my $query = new CGI;
my $cookie = "SESS_ID";
#my $id = $query->cookie(-name => "$cookie");
my $ip = "";

###################
#
# If logged in
#
###################

#if($id){
#my $dbh = #DBI->connect("DBI:mysql:doncote_draft:localhost","doncote_draft","draft")
#              or die "Couldn't connect to database: " .  DBI->errstr;
#$sth = $dbh->prepare("SELECT user, ip FROM sessions WHERE sess_id = '$id'")
#      or die "Cannot prepare: " . $dbh->errstr();
#$sth->execute() or die "Cannot execute: " . $sth->errstr();
#($user,$ip) = $sth->fetchrow_array();
#0}


if($ip == $ENV{REMOTE_ADDR})
{

   #get name
#   $sth = $dbh->prepare("SELECT name FROM passwd WHERE user = '$user'")
#       or die "Cannot prepare: " . $dbh->errstr();
#   $sth->execute() or die "Cannot execute: " . $sth->errstr();
#   my $name = $sth->fetchrow_array();

print <<EOM;

<center>
<table class="login">
   <th>WELCOME</th>
   <tr><td>
TEST
<a href="logout.cgi">Logout</a>
   </td></tr>
</table>
</center>

EOM

#Welcome, $name.<br><br>

}


###################
#
# Not logged in
#
###################

else
{
print <<EOM;

<center>
<table class="login">
   <th>LOGIN</th>
   <tr><td>
<form action="login.cgi" method="post">
Username:<br>
<input type="text" name="user">
<br>
Password<br>
<input type="password" name="passwd"><Br>
<input type="checkbox" name="public">Shared computer.<br>
<button type="submit">Login</button><br>
<a href="register.cgi">Register</a>
</td></tr></table>
</center>

EOM

}


#$dbh->disconnect() if($id);


