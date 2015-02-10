#!/usr/bin/perl
# script to start the RFA draft (set the flag in leagues table)
use DBTools;

($string1, $string2) = split('=',$ENV{'QUERY_STRING'});
$string2 =~ s/%20/ /g;

($league_name, $action) = split(';',$string2);

open(LOG,">./startRfaDraft.log");
print LOG "league_name: $league_name, action: $action\n";
close(LOG);

my $draft_type = 'rfa';
if (uc($action) ne 'START')
{
  $draft_type = 'auction';
}
  

# DB-style
$dbh = dbConnect();
$sth = $dbh->prepare("UPDATE leagues set draft_type='$draft_type' where name='$league_name'");
$sth->execute() or die "Cannot execute: " . $sth->errstr();
$sth->finish();
dbDisconnect($dbh);

print "Content-type: text/html\n\n";
print "OKOKOK";
