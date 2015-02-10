#!/usr/bin/perl

use strict;

use lib qw(. ..);
use Net::MyOAuthApp;
use XML::Simple;
use DBI;

##my $dbh = DBI->connect('DBI:mysql:database=akeely_auction:host=localhost','akeely_auction','@WSXzaq1')
my $dbh = DBI->connect('DBI:mysql:database=akeely_auction:host=127.0.0.1:port=3306','akeely_auction','@WSXzaq1')
          or die "Couldn't connect to database: " .  DBI->errstr;

## game_key = number representing sport / year (http://developer.yahoo.com/fantasysports/guide/game-resource.html)
##            - for current year per sport, just use 'mlb' or 'nfl'
##  2010 nfl = 242
##  2011 nfl = 257
##  2010 mlb = 238
##  2011 mlb = 253
## league_key = {game_key}.l.{league_id}
##  2010 nfl auction - league ID 513310
## team_key = {league_key}.t.{team_id} = {game_key}.l.{league_id}.t.{team_id}
my $game_key = 242;
my $league_id = 513310;
my $team_id = 10; ## Belyea
my $league_key = "${game_key}.l.${league_id}";
my $team_key = "${game_key}.l.${league_id}.t.${team_id}";


## Connect to Yahoo Oauth
my $oauth = Net::MyOAuthApp->new();
$oauth->ConnectToYahoo();

## Access the teams list?
my $url = "http://fantasysports.yahooapis.com/fantasy/v2/league/$league_key/transactions";
##my $url = "http://fantasysports.yahooapis.com/fantasy/v2/league/$league_key/settings";

my $data = $oauth->view_restricted_resource("$url");

open(OUT,">check_yahoo.messages.out");
print OUT $data->{_content} . "\n\n";
close(OUT);
