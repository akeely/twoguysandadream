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

my $sth_update_targets = $dbh->prepare("update targets set playerid=? where playerid=?");
my $sth_update_playerswon = $dbh->prepare("update players_won set name=? where name=?");
my $sth_update_auctionplayers = $dbh->prepare("update auction_players set name=? where name=?");
my $sth_update_finalrosters = $dbh->prepare("update final_rosters set name=? where name=?");
my $sth_update_players = $dbh->prepare("update players set playerid=? where playerid=?");
my $sth_update_contracts = $dbh->prepare("update contracts set player=? where player=?");

my $sth_fetch_players = $dbh->prepare("select playerid, yahooid, name, position, active from players");

my $newid = 110000;
$sth_fetch_players->execute();
while (my ($playerid, $yahooid, $name, $position, $active) = $sth_fetch_players->fetchrow_array())
{
        eval 
        {
          $sth_update_targets->execute($newid,$playerid);
          $sth_update_playerswon->execute($newid,$playerid);
          $sth_update_auctionplayers->execute($newid,$playerid);
          $sth_update_finalrosters->execute($newid,$playerid);
          $sth_update_contracts->execute($newid,$playerid);   
          $sth_update_players->execute($newid,$playerid);

          $dbh->commit();

          $newid++;
        };

        if ($@)
        {
          print "Error during update for $name ($playerid)\n";
          $dbh->rollback();
        }
}


$sth_update_targets->finish();
$sth_update_playerswon->finish();
$sth_update_auctionplayers->finish();
$sth_update_finalrosters->finish();
$sth_update_players->finish();
$sth_update_contracts->finish();

$dbh->disconnect();
print "DONE\n";
