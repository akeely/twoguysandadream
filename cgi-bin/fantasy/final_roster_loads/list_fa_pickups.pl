#!/usr/bin/perl
#
# This script will scan all FA pickups throughout the season and update player draft prices to match the FA pickup positional minimum if the draft price is less than that value.
#


use strict;

use lib qw(. ..);
use Net::MyOAuthApp;
use XML::Simple;
use DBI;
use Time::Local;
use DBTools;
use Data::Dumper;

my $dbh = dbConnect();
## game_key = number representing sport / year (http://developer.yahoo.com/fantasysports/guide/game-resource.html)
##            - for current year per sport, just use 'mlb' or 'nfl'
##  2010 nfl = 242
##  2011 nfl = 257
##  2010 mlb = 238
##  2011 mlb = 253
##  2012 nfl = 273
## league_key = {game_key}.l.{league_id}
##  2010 nfl auction - league ID 513310
##  2011 mlb auction - 152884
##  2011 nfl auction - 503339
##  2012 nfl auction - 540994
## team_key = {league_key}.t.{team_id} = {game_key}.l.{league_id}.t.{team_id}
my $game_key = 346;
my $league_id = 39209;
my $auction_league_name = '2015 Baseball Auction';
my $team_id = 2; 
my $league_key = "${game_key}.l.${league_id}";
my $team_key = "${game_key}.l.${league_id}.t.${team_id}";


## Connect to Yahoo Oauth
my $oauth = Net::MyOAuthApp->new();
$oauth->ConnectToYahoo();

## Get league data to see trade deadline
my $url = "http://fantasysports.yahooapis.com/fantasy/v2/league/$league_key";

my $data = $oauth->view_restricted_resource("$url/settings");

my $league_data = XMLin($data->{_content});
open(ROSTER,">./fa_pickups_$league_id.log");

## Fetch transaction data
$data = $oauth->view_restricted_resource("$url/transactions");
my $transaction_data = XMLin($data->{_content}, forcearray => [ 'player' ]);
my @transactions = @{$transaction_data->{league}->{transactions}->{transaction}};
my %players;
foreach my $t (@transactions)
{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($t->{timestamp});
  $mon++;
  $year += 1900;
  foreach my $player (@{$t->{players}->{player}})
  {
    next if ($player->{transaction_data}->{type} ne 'add');
    $players{$player->{player_id}}->{NAME} = $player->{name}->{full};
    $players{$player->{player_id}}->{POS} = $player->{display_position};
  }
}

## Fetch FA default values for this league
my %fa_values;
my $sth_fetch_fa_values = $dbh->prepare("select position, price from fa_keepers where league='$auction_league_name'");
$sth_fetch_fa_values->execute();
while (my($pos,$price) = $sth_fetch_fa_values->fetchrow_array()) {
  $fa_values{$pos} = $price;
}
$sth_fetch_fa_values->finish();

my $sth_check_fa = $dbh->prepare("select r.name, r.price, r.team from final_rosters r, players p where p.yahooid=? and p.playerid=r.name and r.league='$auction_league_name'");
my $sth_update_fa = $dbh->prepare("update final_rosters set price=0 where name=? and league='$auction_league_name'");
foreach my $check_player (keys %players) {
  my $fa_price = 0;
  if (defined $fa_values{$players{$check_player}->{POS}}) {
    $fa_price = $fa_values{$players{$check_player}->{POS}};
  } else {
    for my $pos (split(/,/, $players{$check_player}->{POS})) {
    
      if ($fa_values{$pos} > $fa_price) {
        print "\tUsing $pos price $fa_values{$pos} for $players{$check_player}->{NAME}\n";
        $fa_price = $fa_values{$pos};
      } else {
        print "\t\tSkipping position $pos ($fa_values{$pos} !> $fa_price)\n";
      }
    }
  }
  
  $sth_check_fa->execute($check_player);
  my ($id, $price, $team) = $sth_check_fa->fetchrow_array();
  next if ($team eq 'NONE');

  if (($price > 0) && ($price < $fa_price)) {
    print "$team: " . $players{$check_player}->{NAME} . ',' . $players{$check_player}->{POS} . ": $price => $fa_price\n";
    $sth_update_fa->execute($id);
  }
}
$sth_check_fa->finish();
$sth_update_fa->finish();

close(ROSTER);
