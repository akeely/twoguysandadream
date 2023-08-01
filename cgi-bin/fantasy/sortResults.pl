#!/usr/bin/perl
use DBI;
use DBTools;
$log = "sortResults_log.txt";

## For UTF-8 characters
binmode(STDOUT, ":utf8");

($string1, $string2) = split('=',$ENV{'QUERY_STRING'});
$string2 =~ s/%20/ /g;

($field, $leagueid, $order) = split(';',$string2);

$return_string = "";

$dbh = dbConnect();

my $query = "SELECT p.name, w.price, t.name, w.time, p.position FROM players_won w, players p, teams t WHERE w.leagueid = $leagueid AND w.playerid=p.playerid AND t.id=w.teamid";
my $order = " ORDER BY ${field} $order, p.position";
if ($field eq 'position')
{
  $order = " ORDER BY p.position $order, w.team";
}


$sth = $dbh->prepare("${query}${order}");
$sth->execute() or die "Cannot execute: " . $sth->errstr();
 
while( ($player,$cost,$owner,$time,$position) = $sth->fetchrow_array())
{
  if ($time =~ /^$/)
  {
    $time_string = 'KEEPER CONTRACT';
  }
  elsif ($time =~ /\D/)
  {
    $time_string = $time;
  }
  else
  {
    ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime($time);
    $Year += 1900;
    $Month++;
    $Month = "0" . $Month if ($Month < 10);
    $Day = "0" . $Day if ($Day < 10);
    $Hour = "0" . $Hour if ($Hour < 10);
    $Minute = "0" . $Minute if ($Minute < 10);
    $Second = "0" . $Second if ($Second < 10);
    $time_string = "$Month/$Day/$Year at $Hour:$Minute:$Second";
  }
  $return_string = "$return_string;$player,$owner,$position,$cost,$time_string";
}
$sth->finish();
dbDisconnect($dbh);


print "Content-type: text/html\n\n";
print "$return_string";
