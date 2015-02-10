#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use DBI;

#
#print "Content-type: text/html\n\n";


my %cookies = fetch CGI::Cookie;
my $cookie = $cookies{SESS_ID};
my $id = $cookie->value;
$cookie->expires('-1d');
#$cookie->bake;

print $id;

my $dbh = DBI->connect("DBI:mysql:gunsli5_fantasy:localhost","gunsli5_fantasy","820710");
my $sth = $dbh->prepare("DELETE FROM session WHERE sess_id = '$id'")
       or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
my $pwd_check = $sth->fetchrow_array();
$sth->finish();
$dbh->disconnect();

print "Setcookie: $cookie\n";
print "Status: 302 Moved\nLocation: $ENV{HTTP_REFERER}\n\n";