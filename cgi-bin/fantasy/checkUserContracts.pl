#!/usr/bin/perl
# script to check current contracts on the fly
use DBTools;

$log = 'check_contracts.log';

($string1, $string2) = split('=',$ENV{'QUERY_STRING'});
$string2 =~ s/%20/ /g;

($ownerid, $leagueid) = split(';',$string2);
$players_won_file = "players_won";
$contract_table = "contracts";
my $return_string = "";

## Contracts
$dbh = dbConnect();

my $sth_contracts = $dbh->prepare("SELECT playerid,ownerid,total_years,years_left,current_cost,leagueid,locked,broken FROM $contract_table WHERE ownerid = $ownerid AND leagueid = $leagueid");
$sth_contracts->execute() or die "Cannot execute: " . $sth_contracts->errstr();
while (($id,$team,$years,$years_left,$cost,$league,$locked_status,$is_broken) = $sth_contracts->fetchrow_array())
{
   $locked = 0;
   if (($years_left < $years) || ($locked_status eq 'yes'))
   {
     $locked = 1;
   }
   
   $years_left = -2 if ($is_broken eq 'Y');

   $return_string = "$id,C,$years,$locked,$years_left;$return_string";
}
$sth_contracts->finish();

## Get contract info for players that were under contract to other teams (either current contract of just expired)
my $sth_contracts2 =  $dbh->prepare("SELECT c.playerid,c.ownerid,c.total_years,c.years_left,c.current_cost,c.leagueid,c.locked,c.broken FROM contracts c, final_rosters r, teams t WHERE c.leagueid=$leagueid and r.leagueid=c.leagueid and t.leagueid=r.leagueid and c.playerid=r.playerid and t.id=r.teamid and c.ownerid <> t.ownerid and t.ownerid=$ownerid");
$sth_contracts2->execute();
while (($id,$team,$years,$years_left,$cost,$league,$locked_status,$is_broken) = $sth_contracts2->fetchrow_array())
{
   $locked = 0;
   if (($years_left < $years) || ($locked_status eq 'yes'))
   {
     $locked = 1;
   }

   $years_left = -2 if ($is_broken eq 'Y');

   $return_string = "$id,X,$years,$locked,$years_left;$return_string";
}
$sth_contracts2->finish();

## Tag info
## Do not include team in query, since any player franchised last year cannot be tagged again this year
my $sth = $dbh->prepare("SELECT playerid,ownerid,type,locked FROM tags WHERE leagueid = $leagueid");
$sth->execute() or die "Cannot execute: " . $sth->errstr();
while (($id,$team,$type,$locked_status) = $sth->fetchrow_array())
{
   $locked = ($locked_status eq 'yes') ? 1 : 0;
   $return_string = "$id,$type,1,$locked,1;$return_string";
}
$sth->finish();
dbDisconnect($dbh);


print "Content-type: text/html\n\n";
print "$return_string";
