#!/usr/bin/perl

use strict;

use lib qw(. ..);
use Net::MyOAuthApp;
use XML::Simple;
use DBI;
use Encode qw(encode decode);

## Compare each stored player versus our players table - check using lower() and with sport
## Any not found, flag and check manually?

my $dbh = DBI->connect('DBI:mysql:database=akeely_auction:host=127.0.0.1:port=3306','akeely_auction','@WSXzaq1',{RaiseError => 1,AutoCommit => 0})
          or die "Couldn't connect to database: " .  DBI->errstr;

my $sth_fetch_dupes = $dbh->prepare("select p1.yahooid, p1.playerid, p1.sport, p2.playerid, p2.sport FROM players p1, players p2 WHERE p1.yahooid = p2.yahooid AND p1.name != p2.name");
my $sth_update_targets = $dbh->prepare("update targets t, leagues l set t.playerid=? where t.league=l.name and t.playerid=? and l.sport=?");
my $sth_update_playerswon = $dbh->prepare("update players_won p, leagues l set p.name=? where p.league=l.name and p.name=? and l.sport=?");
my $sth_update_auctionplayers = $dbh->prepare("update auction_players p, leagues l set p.name=? where p.league=l.name and p.name=? and l.sport=?");
my $sth_update_finalrosters = $dbh->prepare("update final_rosters f, leagues l set f.name=? where f.league=l.name and f.league=l.name and f.name=? and l.sport=?");
my $sth_update_contracts = $dbh->prepare("update contracts c, leagues l set c.player=? where c.league=l.name and c.player=? and l.sport=?");



$sth_fetch_dupes->execute();
while (my ($yahooid, $pid1, $sport1, $pid2, $sport2) = $sth_fetch_dupes->fetchrow_array())
{
        eval 
        {
#          $sth_update_targets->execute($newid,$playerid);
          $sth_update_targets->execute($pid1,$pid2,$sport1);
print "# of rows swapped from $pid2 to $pid1: " . $sth_update_targets->rows . "\n";
          $sth_update_targets->execute($pid2,$pid1,$sport2);
print "# of rows swapped from $pid1 to $pid2: " . $sth_update_targets->rows . "\n";

          $sth_update_playerswon->execute($pid1,$pid2,$sport1);
print "# of rows swapped from $pid2 to $pid1: " . $sth_update_playerswon->rows . "\n";
          $sth_update_playerswon->execute($pid2,$pid1,$sport2);
print "# of rows swapped from $pid1 to $pid2: " . $sth_update_playerswon->rows . "\n";

          $sth_update_auctionplayers->execute($pid1,$pid2,$sport1);
print "# of rows swapped from $pid2 to $pid1: " . $sth_update_auctionplayers->rows . "\n";
          $sth_update_auctionplayers->execute($pid2,$pid1,$sport2);
print "# of rows swapped from $pid1 to $pid2: " . $sth_update_auctionplayers->rows . "\n";

          $sth_update_finalrosters->execute($pid1,$pid2,$sport1);
print "# of rows swapped from $pid2 to $pid1: " . $sth_update_finalrosters->rows . "\n";
          $sth_update_finalrosters->execute($pid2,$pid1,$sport2);
print "# of rows swapped from $pid1 to $pid2: " . $sth_update_finalrosters->rows . "\n";

          $sth_update_contracts->execute($pid1,$pid2,$sport1);
print "# of rows swapped from $pid2 to $pid1: " . $sth_update_contracts->rows . "\n";
          $sth_update_contracts->execute($pid2,$pid1,$sport2);
print "# of rows swapped from $pid1 to $pid2: " . $sth_update_contracts->rows . "\n";


          $dbh->commit();

        };

        if ($@)
        {
          print "Error during update for $pid1, $pid2\n";
          $dbh->rollback();
        }
}


$sth_update_targets->finish();
$sth_update_playerswon->finish();
$sth_update_auctionplayers->finish();
$sth_update_finalrosters->finish();
$sth_update_contracts->finish();

$dbh->disconnect();
print "DONE\n";
