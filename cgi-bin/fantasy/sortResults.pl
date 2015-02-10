#!/usr/bin/perl
use DBI;
use DBTools;
$log = "sortResults_log.txt";

## For UTF-8 characters
binmode(STDOUT, ":utf8");

($string1, $string2) = split('=',$ENV{'QUERY_STRING'});
$string2 =~ s/%20/ /g;

($field, $league_t, $order) = split(';',$string2);

$return_string = "";

$dbh = dbConnect();

if ($field eq 'price')
{
  $sth = $dbh->prepare("SELECT p.name, w.price, w.team, w.time, p.position FROM players_won w, players p WHERE w.league = '$league_t' and w.name=p.playerid ORDER BY w.${field} $order, p.position");
}
elsif ($field eq 'position')
{
  $sth = $dbh->prepare("SELECT p.name, w.price, w.team, w.time, p.position FROM players_won w, players p WHERE w.league = '$league_t' and w.name=p.playerid ORDER BY p.position $order, w.team");
}
else
{
  $sth = $dbh->prepare("SELECT p.name, w.price, w.team, w.time, p.position FROM players_won w, players p WHERE w.league = '$league_t' and w.name=p.playerid ORDER BY w.${field} $order, p.position");
}

$sth->execute() or die "Cannot execute: " . $sth->errstr();
 
while( ($player,$cost,$owner,$time,$position) = $sth->fetchrow_array())
{
  if ($time =~ /^$/)
  {
    $time_string = 'KEEPER CONTRACT';
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
