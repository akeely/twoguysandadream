#!/usr/bin/perl
# script to check current tags on the fly
use DBTools;

$log = 'check_contracts.log';

($string1, $string2) = split('=',$ENV{'QUERY_STRING'});
$string2 =~ s/%20/ /g;

($ownerid, $leagueid) = split(';',$string2);
$players_won_file = "players_won";
$tags_table = "tags";
$return_string = "";

# DB-style
$dbh = dbConnect();

$sth = $dbh->prepare("SELECT t.playerid,t.type,t.locked,p.name,p.position FROM $tags_table t, players p WHERE t.ownerid = $ownerid AND t.leagueid = $leagueid and t.playerid=p.playerid and t.active='yes'")
       or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
while (my ($id,$type,$locked_status,$name,$pos) = $sth->fetchrow_array())
{
   $locked = ($locked_status eq 'yes') ? 1 : 0;
   my $display_string = "$name - $pos";
   
   $return_string = "$display_string,$type,$locked;$return_string";
}
$sth->finish();
dbDisconnect($dbh);


print "Content-type: text/html\n\n";
print "$return_string";
