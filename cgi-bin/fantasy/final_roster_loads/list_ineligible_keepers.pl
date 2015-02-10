#!/usr/bin/perl

use strict;

use lib qw(. ..);
use Net::MyOAuthApp;
use XML::Simple;
use DBI;
use Time::Local;
use DBTools;

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
my $game_key = 314;
my $league_id = 548917;
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
my $trade_end_date = $league_data->{league}->{settings}->{trade_end_date};
print "Trade End: $trade_end_date\n";  ##2010-11-12
my ($year,$month,$day) = split(/\-/,$trade_end_date);  
$month--;
my $trade_end_epoch = timelocal(0,0,0,$day,$month,$year);
print LOG "Epoch: $trade_end_epoch\n";
print "Epoch: $trade_end_epoch\n";

open(ROSTER,">./roster_check.log");

## Fetch transaction data
$data = $oauth->view_restricted_resource("$url/transactions");
my $transaction_data = XMLin($data->{_content}, forcearray => [ 'player' ]);
my @transactions = @{$transaction_data->{league}->{transactions}->{transaction}};
my @players;
foreach my $t (@transactions)
{
  next if ($t->{timestamp} <= $trade_end_epoch);

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($t->{timestamp});
  $mon++;
  $year += 1900;
  foreach my $player (@{$t->{players}->{player}})
  {
    ##next if ($player->{transaction_data}->{type} ne 'add');
    print "$player->{player_id}: $player->{transaction_data}->{type} $player->{name}->{full} ($mon/$mday/$year)\n";
    print ROSTER "$player->{player_id}: $player->{transaction_data}->{type} $player->{name}->{full} ($mon/$mday/$year)\n";
    print ROSTER "\t$player->{transaction_data}->{type}\n";
    print ROSTER "\t$player->{transaction_data}->{source_team_key} | $player->{transaction_data}->{destination_team_key}\n";

      push(@players,$player->{player_id});
  }

}

##print join(',',@players) . "\n\n";

close(ROSTER);
