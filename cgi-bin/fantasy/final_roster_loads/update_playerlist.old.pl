#!/usr/bin/perl

use strict;

use lib qw(. ..);
use Net::MyOAuthApp;
use XML::Simple;
use DBI;
use Encode qw(encode decode);

my $enc = 'unicode';

## game_key = number representing sport / year (http://developer.yahoo.com/fantasysports/guide/game-resource.html)
##            - for current year per sport, just use 'mlb' or 'nfl'
##  2010 nfl = 242
##  2011 nfl = 257
##  2010 mlb = 238
##  2011 mlb = 253
## league_key = {game_key}.l.{league_id}
##  2010 nfl auction - league ID 513310
##  2011 nfl auction - league ID 503339
##  2011 mlb auction - 152884
##  2012 mlb auction - 80930
##  2012 nfl auction - 540994
## team_key = {league_key}.t.{team_id} = {game_key}.l.{league_id}.t.{team_id}
##my $sport = 'football';
##my $game_key = 'nfl';
my $sport = 'baseball';
my $game_key = 'mlb';
my $league_key = $game_key . ".l.39507";

## Translation for Yahoo team defenses to ESPN/TGaaD storage (football only)
my %team_lut = (
                 'Arizona' => 'Cardinals',,
                 'Atlanta' => 'Falcons',,
                 'Baltimore' => 'Ravens',
                 'Buffalo' => 'Bills',
                 'Carolina' => 'Panthers',
                 'Chicago' => 'Bears',
                 'Cincinnati' => 'Bengals',
                 'Cleveland' => 'Browns',
                 'Dallas' => 'Cowboys',
                 'Denver' => 'Broncos',
                 'Detroit' => 'Lions',
                 'Green Bay' => 'Packers',
                 'Houston' => 'Texans',
                 'Indianapolis' => 'Colts',
                 'Jacksonville' => 'Jaguars',
                 'Kansas City' => 'Chiefs',
                 'Miami' => 'Dolphins',
                 'Minnesota' => 'Vikings',
                 'New England' => 'Patriots',
                 'New Orleans' => 'Saints',
                 'New York Giants' => 'Giants',
                 'New York Jets' => 'Jets',
                 'Oakland' => 'Raiders',
                 'Philadelphia' => 'Eagles',
                 'Pittsburgh' => 'Steelers',
                 'San Diego' => 'Chargers',
                 'San Francisco' => '49ers',
                 'Seattle' => 'Seahawks',
                 'St. Louis' => 'Rams',
                 'Tampa Bay' => 'Buccaneers',
                 'Tennessee' => 'Titans',
                 'Washington' => 'Redskins'
                     );



## Connect to Yahoo Oauth
my $oauth = Net::MyOAuthApp->new();


## Abstract this here for ease of testing ...
my $player_data;
my $league_settings;
my $trade_end_date;
my %yahoo_players;
if (1)
{
  $oauth->ConnectToYahoo();

  ## Results seem to come bunched in groups of 25 ... so need to just keep pinging away til we max out the results?
  my $count = 0;
  my $max = 25;
  
  while ($count < 2500)
  {
    my $url = "http://fantasysports.yahooapis.com/fantasy/v2/league/$league_key/players;start=$count;sort=OR";
    my $data = $oauth->view_restricted_resource("$url");

    $player_data = XMLin($data->{_content}, forcearray => [ 'team' ]);

    my @players;
    eval { @players = @{$player_data->{league}->{players}->{player}}; };
    last if ($@);
    
    foreach my $player(@players)
    {
      $count++;

      if (defined $yahoo_players{$player->{player_id}})
      {
        print "DUPLICATE? $player->{player_id} ... $player->{name}->{full} versus $yahoo_players{$player->{player_id}}\n";
      }

      if ($player->{display_position} eq 'DEF')
      {
        $player->{name}->{full} = $team_lut{$player->{name}->{full}} || $team_lut{$player->{editorial_team_full_name}};
      }
      $player->{name}->{full} =~ s/\'//g;
      $yahoo_players{$player->{player_id}}->{NAME} = $player->{name}->{full};
      $yahoo_players{$player->{player_id}}->{POS} = $player->{display_position};
      $yahoo_players{$player->{player_id}}->{TEAM} = $player->{editorial_team_abbr};
      $yahoo_players{$player->{player_id}}->{RANK} = $count;
    }
  }

  print "Count = $count, found " . (keys %yahoo_players) . " players total!\n";
  open(TMP,">TMP");
  foreach my $p (keys %yahoo_players)
  {
    print TMP "$yahoo_players{$p}->{NAME} ($p)\n";
  }
  close(TMP);
  
    
##  open (TMP,">TMP");
##  print TMP $data->{_content} . "\n";
##  close(TMP);
}
else
{
  $player_data = XMLin("TEST_CONTENT", forcearray => [ 'team' ]);
}


## Debug output ...
##print "PLAYERS:\n";
##foreach my $player (@players)
##{
##  foreach my $k (keys %{$player})
##  {
##    print "$k: $player->{$k}\n";
##  }
##  print "\n";
##}
#print "TEAMS\n";
#foreach my $k (keys %$teams)
#{
#  print "$k: $teams->{$k}\n";
#}


## Compare each stored player versus our players table - check using lower() and with sport
## Any not found, flag and check manually?

my $dbh = DBI->connect('DBI:mysql:database=akeely_auction:host=127.0.0.1:port=3306','akeely_auction','@WSXzaq1',{RaiseError => 1,AutoCommit => 0})
          or die "Couldn't connect to database: " .  DBI->errstr;

my $sth_deactivate_player = $dbh->prepare("update players set active=0 where playerid=?");
my $sth_update_targets = $dbh->prepare("update targets set playerid=? where playerid=?");
my $sth_update_playerswon = $dbh->prepare("update players_won set name=? where name=?");
my $sth_update_auctionplayers = $dbh->prepare("update auction_players set name=? where name=?");
my $sth_update_finalrosters = $dbh->prepare("update final_rosters set name=? where name=?");
my $sth_update_players = $dbh->prepare("update players set yahooid=?, team=?, rank=?, active=1 where playerid=?");
my $sth_update_playername = $dbh->prepare("update players set name=? where yahooid=?");
my $sth_update_contracts = $dbh->prepare("update contracts set player=? where player=?");

my $sth_fetch_players = $dbh->prepare("select playerid, yahooid, name, position, active from players where sport='$sport'");
$sth_fetch_players->execute();
 my $auction_ref = $sth_fetch_players->fetchall_hashref('yahooid');
$sth_fetch_players->finish();

open(ERIK,">ERIK");
my $old_fh = select(ERIK);
$| = 1;
select($old_fh);

foreach my $auctionid (keys %$auction_ref)
{
  my $match = 0;
  foreach my $yahooid (keys %yahoo_players)
  {

    ## Handle upper-casing without encoding so we can handle special characters
    my $auction_name = decode($enc, $auction_ref->{$auctionid}->{name});
    $auction_name = encode($enc, uc $auction_name);
    my $yahoo_name = decode($enc, $yahoo_players{$yahooid}->{NAME});
    $yahoo_name = encode($enc, uc $yahoo_name);

    if ($auction_name eq $yahoo_name)
    {
      print "MATCH!\n\t$auction_ref->{$auctionid}->{name}\t$yahoo_players{$yahooid}->{NAME}\n";
      print ERIK "MATCH!\n\t$auction_ref->{$auctionid}->{name}\t$yahoo_players{$yahooid}->{NAME}\n";
      print ERIK "\t$auction_ref->{$auctionid}->{position}\t$yahoo_players{$yahooid}->{POS}\n";
      print ERIK "\t$yahoo_players{$yahooid}->{TEAM}, RANK $yahoo_players{$yahooid}->{RANK}\n\n";

      $match = 1;

      ## Update player in tables:
      ##  players
      ##  players_won
      ##  auction_players
      ##  final_rosters
      ##  contracts
      ##  targets

## Update the players table no matter what
##      if ($auctionid != $yahooid)
      if (1)
      {
        eval 
        {
## Below tables are all based on playerid, not yahooid
##          $sth_update_targets->execute($yahooid,$auctionid);
##          $sth_update_playerswon->execute($yahooid,$auctionid);
##          $sth_update_auctionplayers->execute($yahooid,$auctionid);
##          $sth_update_finalrosters->execute($yahooid,$auctionid);
##          $sth_update_contracts->execute($yahooid,$auctionid);   

          $sth_update_players->execute($yahooid,$yahoo_players{$yahooid}->{TEAM},$yahoo_players{$yahooid}->{RANK},$auction_ref->{$auctionid}->{playerid});
          $dbh->commit();
        };

        if ($@)
        {
          print "Error during update for $yahoo_players{$yahooid}->{NAME} ($yahooid)\n";
          $dbh->rollback();
        }
      }

##print ERIK "Goodbye $yahooid\n";
      delete $yahoo_players{$yahooid};
      last;
    }
  }

  if ((! $match) && ($auction_ref->{$auctionid}->{active}))
  {

    ## Only consider deactivating if we are looking at current rosters
    if (($game_key eq 'nfl') || ($game_key eq 'mlb'))
    {
      print "NO MATCH for $auction_ref->{$auctionid}->{name} ($auction_ref->{$auctionid}->{position}) ($yahoo_players{$auctionid}->{NAME})\n";
##      print ERIK "NO MATCH for $auction_ref->{$auctionid}->{name} ($auction_ref->{$auctionid}->{position})\n";

      my $ans = '';
      while (1)
      {
        if ((defined ($yahoo_players{$auctionid}->{NAME})) && ($yahoo_players{$auctionid}->{NAME} !~ /^$/))
        {
        	print "Options:\n\tD - Deactivate in DB\n\tM - Map by YahooID (to $yahoo_players{$auctionid}->{NAME})\n\tS - Skip, do nothing\n:";
        	$ans = <STDIN>;
        	chomp($ans);
		last if (($ans eq 'D') || ($ans eq 'M') || ($ans eq 'S'));
	}
	else
	{
        	print "Options:\n\tD - Deactivate in DB\n\tS - Skip, do nothing\n:";
        	$ans = <STDIN>;
        	chomp($ans);
		last if (($ans eq 'D') || ($ans eq 'S'));
	}
      }

      if ($ans eq 'D')
      {
        $sth_deactivate_player->execute($auction_ref->{$auctionid}->{playerid});
        $dbh->commit();
      }

      if ($ans eq 'M')
      {
        $sth_update_playername->execute($yahoo_players{$auctionid}->{NAME},$auctionid);
	$dbh->commit();
        delete $yahoo_players{$auctionid};
      }
    }
  }
}

$sth_update_targets->finish();
$sth_update_playerswon->finish();
$sth_update_auctionplayers->finish();
$sth_update_finalrosters->finish();
$sth_update_players->finish();
$sth_update_contracts->finish();

## Only insert if we are looking at current rosters
if (($game_key eq 'nfl') || ($game_key eq 'mlb'))
{
  my $sth_insert_player = $dbh->prepare("insert into players (name,sport,position,team,rank,active,yahooid) values (?,'$sport',?,?,?,1,?)");

  foreach my $yahooid (keys %yahoo_players)
  {
    print "New player! $yahoo_players{$yahooid}->{NAME} ($yahooid)\n";
    print ERIK "New player! $yahoo_players{$yahooid}->{NAME} ($yahooid)\n";

    ## Insert into players table
    eval 
    {
      $sth_insert_player->execute($yahoo_players{$yahooid}->{NAME},$yahoo_players{$yahooid}->{POS},$yahoo_players{$yahooid}->{TEAM},$yahoo_players{$yahooid}->{RANK},$yahooid);
      $dbh->commit();
    };
    if ($@)
    {
      print "ERROR: $@\n";
      $dbh->rollback();
    }
  }

  $sth_insert_player->finish();
}

$dbh->disconnect();
close(ERIK);

print "DONE\n";
