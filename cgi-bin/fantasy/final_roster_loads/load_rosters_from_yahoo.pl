#!/usr/bin/perl

use strict;

use lib qw(. ..);
use Net::MyOAuthApp;
#use Net::MyOAuthApp_Oauth1;
use XML::Simple;
use DBI;
use Time::Local;
use DBTools;
use Data::Dumper;

## game_key = number representing sport / year (http://developer.yahoo.com/fantasysports/guide/game-resource.html)
##            - for current year per sport, just use 'mlb' or 'nfl'
## ALSO - can use the YQL console to check IDs and eventually find our match: https://developer.yahoo.com/yql/console/
#
# NOTE - stay on top of these game ids each year, getting the current game_key id via fetch_yahoo_game_ids.pl
#
##  2010 nfl = 242
##  2011 nfl = 257
##  2010 mlb = 238
##  2011 mlb = 253
##  2012 nfl = 273
##  2012 mlb = 268
##  2013 mlb = 308
##  2013 nfl = 314  **
##  2014 mlb = 328  **
##  2014 nfl = 331
##  2015 mlb = 346
##  2015 nfl = 348
##  2016 nfl = 359
##  2016 mlb = 357
##  2017 mlb = 370 
##  2017 nfl = 371
##  2018 mlb = 378
##  2018 nfl = 380
##  2019 mlb = 388
##  2019 nfl = 390
##  2020 mlb = 398
##  2020 nfl = 399
##  2021 mlb = 404
##  2021 nfl = 406
##  2022 mlb = 412
##  2022 nfl = 414
##  2023 mlb = 422
##  2023 nfl = 

## league_key = {game_key}.l.{league_id}
##  2010 nfl auction - league ID 513310
##  2011 mlb auction - league ID 152884
##  2011 nfl auction - league ID 503339
##  2012 mlb auction - 80930
##  2012 nfl auction - 540994
##  2012 mlb auction - 80930
##  2013 nfl auction - 548917
##  2013 mlb auction - 39507
##  2014 nfl auction - 339579
##  2014 mlb auction - 101127
##  2019 mlb auction - 124666
##  2019 nfl auction - 384517
##  2020 mlb auction - 34523
##  2020 nfl auction - 822779
##  2021 mlb auction - 91804
##  2021 nfl auction - 386369
##  2022 mlb auction - 82250
##  2022 nfl auction - 261882
##  2023 mlb auction - 91572
##  2023 nfl auction - 
## team_key = {league_key}.t.{team_id} = {game_key}.l.{league_id}.t.{team_id}
my $game_key = 412;
my $league_key = 82250;

my $sport = '';
print "Enter the sport [(b)aseball|(f)ootball]: ";
while (($sport ne 'baseball') && ($sport ne 'football') && ($sport ne 'b') && ($sport ne 'f'))
{
  print "Invalid entry '$sport'\n :" if ($sport ne '');
  $sport = <STDIN>;
  chomp($sport);
}

$sport = 'baseball' if ($sport eq 'b');
$sport = 'football' if ($sport eq 'f');

## Connect to Yahoo Oauth
my $oauth = Net::MyOAuthApp->new();
#my $oauth = Net::MyOAuthApp_Oauth1->new();

print "\n\n\nOK\n\n\n";


## Abstract this here for ease of testing ...
my $data;
my $teams_data;
my $league_settings;
my $trade_end_date;
my @transactions;
if (1)
{
  $oauth->ConnectToYahoo();

print "CONNECTED\n\n";

$oauth->view_restricted_resource("https://fantasysports.yahooapis.com/fantasy/v2/game/mlb");

  ## Access the teams list?
  my $url = "https://fantasysports.yahooapis.com/fantasy/v2/league/${game_key}.l.${league_key}";
  $data = $oauth->view_restricted_resource("${url}/teams");

print "TEAMS??\n\n";
open(TEST,">TEAMS_REQUEST_RESPONSE");
print TEST "$data->{_content}\n\n";
close(TEST);

  $teams_data = XMLin($data->{_content}, forcearray => [ 'team' ]);

  $data = $oauth->view_restricted_resource("$url/settings");
  $league_settings = XMLin($data->{_content});
  $trade_end_date = $league_settings->{league}->{settings}->{trade_end_date};

  ## Store transactions for later
  $data = $oauth->view_restricted_resource("$url/transactions");
  my $transactions_data = XMLin($data->{_content}, forcearray => [ 'player' ]);
  @transactions = @{$transactions_data->{league}->{transactions}->{transaction}};
}
else
{
  $teams_data = XMLin("TEST_CONTENT", forcearray => [ 'team' ]);
}

## Get hashref of teams data
my $teams = $teams_data->{league}->{teams}->{team};


## Debug output ...
##print "SETTINGS:\n";
##foreach my $k (keys %{$league_settings->{league}->{settings}})
##{
##  print "$k: $league_settings->{league}->{settings}->{$k}\n";
##}
#print "TEAMS\n";
#foreach my $k (keys %$teams)
#{
#  print "$k: $teams->{$k}\n";
#}

my $dbh = dbConnect();

## Matchup files for yahoo teams => auction teams
my %ateams;
my $aleague;
my $yleagueid;
print "Which auction site league are you importing to? ";
$aleague = <STDIN>;
chomp($aleague);
my $sth_fetch_league_id = $dbh->prepare("select id from leagues where name='$aleague'");
$sth_fetch_league_id->execute();
$yleagueid = $sth_fetch_league_id->fetchrow();

my %matchups;
my $matchup_file = "owner_matchup.$game_key.$league_key";
if (-f "$matchup_file")
{
  my $linect = 0;
  open(MATCHUP,"<$matchup_file");
  foreach my $line (<MATCHUP>)
  {
    chomp($line);
    if ($linect++ == 0)
    {
      $aleague = $line;
      next;
    }
    my ($yteam,$ateam) = split(/\:\:/,$line);
    $matchups{$yteam} = $ateam;
  }
}
else
{

  my $sth_fetch_auction_teams = $dbh->prepare("select id,name from teams where leagueid = $yleagueid");
  $sth_fetch_auction_teams->execute();
  my $count = 1;
  while (my ($ateamid,$ateam) = $sth_fetch_auction_teams->fetchrow_array())
  {
    $ateams{$count++} = $ateam . '||' . $ateamid;
  }
  $sth_fetch_auction_teams->finish();
  $sth_fetch_league_id->finish();
}


  

## If teams are not already matched up, prompt the user for input
my $prompt_input = 0;
$prompt_input = 1 if ((keys %matchups) < 1);

while (1)
{
  prompt_matchups() if ($prompt_input);

  print_matchups();

  my $ans = '';
  while (($ans ne 'Y') && ($ans ne 'N'))
  {
    print "Are these matchups correct? [Y/N]? ";
    $ans = <STDIN>;
    chomp($ans);
  }

  last if $ans eq 'Y';
  $prompt_input = 1;
}

## Print the updated matchup to the file, if it has changed/is new
if ($prompt_input)
{
  open(MATCHUP,">$matchup_file");
  print MATCHUP "$aleague\n";
  foreach my $yteam (keys %matchups)
  {
    print MATCHUP "${yteam}::" . $matchups{$yteam} . "\n";
  }
  close(MATCHUP);
}

my $sth_fetch_player_id = $dbh->prepare("select playerid from players where yahooid=? and sport='$sport'");
my $sth_clear = $dbh->prepare("update final_rosters set teamid=-1 where leagueid=$yleagueid");
my $sth_select = $dbh->prepare("SELECT * FROM final_rosters WHERE playerid=? and leagueid=$yleagueid");
my $sth_replace = $dbh->prepare("update final_rosters set teamid=? where playerid=? and leagueid=$yleagueid");
my $sth_insert = $dbh->prepare("insert into final_rosters (playerid,price,teamid,leagueid) values (?,0,?,$yleagueid)");


## Assign all players from this draft to 'NONE' owner. Real (current) owner will be assigned below
$sth_clear->execute();
$sth_clear->finish();

open(LOG,">./load_rosters.log");

## Cache info on players that were added after the deadline
print "Trade End: $trade_end_date\n";
my %invalid_adds;
my ($year,$month,$day) = split(/\-/,$trade_end_date);
$month--;
$day++; # players added day-of are legit keeper options
my $trade_end_epoch = timelocal(59,59,23,$day,$month,$year);
foreach my $t (@transactions)
{
  next if ($t->{timestamp} <= $trade_end_epoch);

  foreach my $player (@{$t->{players}->{player}})
  {
    next if ($player->{transaction_data}->{type} ne 'add');
    $invalid_adds{$player->{player_id}} = 1;
  }
}


## Cycle through team_key entries from yahoo to extract rosters
my %rosters;
foreach my $team (keys %$teams)
{
  my $team_key = $teams->{$team}->{team_key};
  my $url = "https://fantasysports.yahooapis.com/fantasy/v2/team/$team_key/roster";

  eval { $data = $oauth->view_restricted_resource("$url"); };
  if ($@)
  {
    ## NFL games do not support rosters by date, so try by week instead
    ##  We typically use week 10 trade deadline ...
## ECW - no long need this condition - right? We handle invalid (late) adds by timestamp above
    ##$data = $oauth->view_restricted_resource("$url;week=10");
  }

  print "Loading $matchups{$team} ($team)\n";
  my @ateam = split(/\|\|/,$matchups{$team});
  my $ateamid = $ateam[1];

  my $roster_data = XMLin($data->{_content});
  ##my $roster_data = XMLin($data->{_content}, forcearray => [ 'team' ]);
##print LOG Dumper($data);

  my @players = @{$roster_data->{team}->{roster}->{players}->{player}};
  foreach my $player (@players)
  {
    print "Player ID: $player->{player_id}\n";
    print "\tPlayer Name: $player->{name}->{full}\n";
    print "\tTeam: $player->{editorial_team_abbr}\n";
    print "\n";
    print "$player->{name}->{full} ($player->{player_id})\n";

    ## If not on season-end roster, cannot be kept
    if (defined $invalid_adds{$player->{player_id}})
    {
      print "$player->{name}->{full} ($player->{player_id}) was added after the deadline! SKIP\n";
      print LOG "$player->{name}->{full} ($player->{player_id}) was added after the deadline! SKIP\n";
      next;
    }


    ## Get auction-specific playerID, if one exists
    $sth_fetch_player_id->execute($player->{player_id});
    my $auctionid = $sth_fetch_player_id->fetchrow();
    if (! defined $auctionid)
    {
      print "NO 'PLAYERS' RECORD FOR YAHOO ID $player->{player_id} ($player->{name}->{full})\n";
      print LOG "NO 'PLAYERS' RECORD FOR YAHOO ID $player->{player_id} ($player->{name}->{full})\n";
      next;
    }

    ## If there is row for the player in the DB, update to the correct owner data
## TODO check for FA status first - was player dropped?
    $sth_select->execute($auctionid);
    if (my @player_row = $sth_select->fetchrow_array())
    {
print "Update record for player '$player->{name}->{full}' ($auctionid), team '$team'\n";
print LOG "Update record for player '$player->{name}->{full}' ($auctionid), team '$team'\n";
      $sth_replace->execute($ateamid, $auctionid);
    }

    ## Else, add new row for this player - who was undrafted at start of season
    else
    {
print "Insert new record for player '$player->{name}->{full}', team '$team'\n";
print LOG "Insert new record for player '$player->{name}->{full}', team '$team'\n";
      $sth_insert->execute($auctionid,$ateamid);
    }
  }
  print "\n";
  print LOG "\n";
}


$sth_fetch_player_id->finish();
$sth_select->finish();
$sth_replace->finish();
$sth_insert->finish();
$dbh->disconnect();

close(LOG);



sub prompt_matchups
{
  print "AUCTION LEAGUE '$aleague' TEAMS:\n";
  foreach my $yteam (sort keys %$teams)
  {
    foreach my $ateamno (sort {$a <=> $b} keys %ateams)
    {
      print "\t$ateamno\t$ateams{$ateamno}\n";
    }
  
    while (1)
    {
      print "\nTeam Number that links to Yahoo team '$yteam':";
      my $inteam = <STDIN>;
      chomp($inteam);

      if (($inteam !~ /\D/) && (defined $ateams{$inteam}))
      {
        $matchups{$yteam} = $ateams{$inteam};
        delete $ateams{$inteam};
        last;
      }

      print "Please enter the NUMBER!\n";
    }
  }
}

sub print_matchups
{
  print "Current Matchups for Auction League '$aleague', Yahoo league '$league_key':\n";
  foreach my $yteam (keys %matchups)
  {
    print "\t$yteam => $matchups{$yteam}\n";
  }
}
