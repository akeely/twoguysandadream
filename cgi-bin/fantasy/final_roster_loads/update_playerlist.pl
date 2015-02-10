#!/usr/bin/perl

use strict;

use lib qw(. ..);
use Net::MyOAuthApp;
use XML::Simple;
use DBI;
use Encode qw(encode decode);
use DBTools;

##binmode(STDOUT, ":utf8");
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
##  2013 nfl auction - 548917
##  2013 mlb auction - 39507
##  2014 nfl auction - 339579
## team_key = {league_key}.t.{team_id} = {game_key}.l.{league_id}.t.{team_id}


## TODO - confirm / change below before running each time
##my $sport = 'baseball';
##my $game_key = 'mlb';
my $sport = 'football';
my $game_key = 'nfl';
my $league_key = $game_key . ".l.339579";

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

  ## Results seem to come bunched in groups of 25 ... so need to just keep pinging away until we max out the results?
  my $count = 0;
  my $max = 25;
  
  open (TMP,">TEST_CONTENT");
  while ($count < 2500)
  {
    my $url = "http://fantasysports.yahooapis.com/fantasy/v2/league/$league_key/players;start=$count;sort=OR";
    my $data = $oauth->view_restricted_resource("$url");

    
if (1)
{
  ##foreach my $k (keys %$data)
  ##{
    ##print TMP "$k => " . $data->{$k} . "\n";
  ##}
  print TMP "$data->{_content}\n";
}

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
  close(TMP);

  print "Count = $count, found " . (keys %yahoo_players) . " players total!\n";
  open(TMP,">TMP");
  foreach my $p (keys %yahoo_players)
  {
    print TMP "$yahoo_players{$p}->{NAME} ($p)\n";
  }
  close(TMP);
  
}
else
{
  $player_data = XMLin("TEST_CONTENT.0", forcearray => [ 'team' ]);

    my @players;
    eval { @players = @{$player_data->{league}->{players}->{player}}; };
    if ($@)
    {
      print "ERROR: $@\n\n";
      exit 1;
    }

    foreach my $player(@players)
    {
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
    }
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

my $dbh = dbConnect();
my $sql = qq{SET NAMES 'utf8';};
$dbh->do($sql);

my $sth_deactivate_player = $dbh->prepare("update players set active=0 where playerid=?");
my $sth_update_players = $dbh->prepare("update players set position=?, team=?, rank=?, active=1 where playerid=?");
my $sth_update_playername = $dbh->prepare("update players set name=? where playerid=?");
my $sth_shift_yahooid = $dbh->prepare("update players set yahooid=? where playerid=?");

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
  if (defined $yahoo_players{$auctionid})
  {
    my $yahooid = $auctionid;
    ## Handle upper-casing without encoding so we can handle special characters
    my $auction_name = decode('utf8', $auction_ref->{$auctionid}->{name});
    $auction_name = encode($enc, uc $auction_name);
    my $yahoo_name = decode($enc, $yahoo_players{$yahooid}->{NAME});
    $yahoo_name = encode($enc, uc $yahoo_name);

    if ($auction_name eq $yahoo_name)
    {
      ##print "MATCH!\n\t$auction_ref->{$auctionid}->{name}\t$yahoo_players{$yahooid}->{NAME}\n";
      print ERIK "MATCH!\n\t$auction_ref->{$auctionid}->{name}\t$yahoo_players{$yahooid}->{NAME}\n";
      print ERIK "\t$auction_ref->{$auctionid}->{position}\t$yahoo_players{$yahooid}->{POS}\n";
      print ERIK "\t$yahoo_players{$yahooid}->{TEAM}, RANK $yahoo_players{$yahooid}->{RANK}\n\n";

      ## This will fall through to update any team/rank/pos data
    }
    else
    {
      ## If IDs match but names are off, prompt the user to confirm
      my $ans = '';
      print "Possible incorrect name mapping for YahooID $auctionid (AUCTION: $auction_name != YAHOO: $yahoo_name):\n";
      print "Options:\n\tR - Replace Auction Name with Yahoo Name\n\tN - Create new Auction player for Yahoo Name (this will retire Auction Name entry)\n\tIf other action needed, break this program and fix manually\n=> ";
      while (1)
      {
        $ans = <STDIN>;
        chomp($ans);
        last if (($ans eq 'R') || ($ans eq 'N'));
      }

      if ($ans eq 'N')
      {
        ## Create new entry for this Yahoo player
        ##  - Deactivate the current Auction player, set his YahooID to '-1' . YahooID (to avoid dupes in this odd scenario)
        ##  - Continue the parent loop of auction players, so this YahooID persists in the hash (and will be handled below)
        $sth_deactivate_player->execute($auction_ref->{$auctionid}->{playerid});
        $sth_shift_yahooid->execute('-1' . $yahooid, $auction_ref->{$auctionid}->{playerid});
        next;
      }
      elsif ($ans eq 'R')
      {
        ## Replace the Auction player name with the Yahoo player name - this should be the case 99.9% of the time ...
        ## This will then fall through to update other data (rank, team, pos) below
        $sth_update_playername->execute(decode($enc,$yahoo_players{$auctionid}->{NAME}),$auction_ref->{$auctionid}->{playerid});
      }
      else
      {
        print "Invalid option? How did we get here?\n\n";
      }

    }


    ## Update player in auction DB
    eval 
    {
      ## Replace any commas in position (ie, 2B,SS) as this is a reserved delimiter down the line (LAME!)
      $yahoo_players{$yahooid}->{POS} =~ s/,/\//g;
      $sth_update_players->execute($yahoo_players{$yahooid}->{POS},$yahoo_players{$yahooid}->{TEAM},$yahoo_players{$yahooid}->{RANK},$auction_ref->{$auctionid}->{playerid});
      $dbh->commit();
    };

    if ($@)
    {
      print "Error during update for $yahoo_players{$yahooid}->{NAME} ($yahooid)\n";
      $dbh->rollback();
    }

    ## Remove the player from the Yahoo hash so that he is not considered for insertion later
    ## Do this even if DB update failed - better to miss a player than have dupe IDs. Right?
    delete $yahoo_players{$yahooid};
  }

  ## If the player is 'active' in TGaaD but not present in Yahoo results, probably time to retire him
  elsif ($auction_ref->{$auctionid}->{active})
  {

    ## Only consider deactivating if we are looking at current rosters
    if (($game_key eq 'nfl') || ($game_key eq 'mlb'))
    {
      print "NO MATCH for $auction_ref->{$auctionid}->{name} ($auction_ref->{$auctionid}->{position})\n";
      print ERIK "NO MATCH for $auction_ref->{$auctionid}->{name} ($auction_ref->{$auctionid}->{position})\n";
      print "Options:\n\tD - Deactivate in DB\n\tS - Skip, do nothing\n:";

      my $ans = '';
#      while (1)
#      {
#        $ans = <STDIN>;
#        chomp($ans);
#	last if (($ans eq 'D') || ($ans eq 'S'));
#      }

$ans = 'D';
      if ($ans eq 'D')
      {
        print ERIK "\tDEACTIVATE\n";
        $sth_deactivate_player->execute($auction_ref->{$auctionid}->{playerid});
        $dbh->commit();
      }
    }
  }
}

$sth_update_players->finish();
$sth_update_playername->finish();
$sth_deactivate_player->finish();

## INSERT NEW PLAYERS
## Only insert if we are looking at current rosters
if (($game_key eq 'nfl') || ($game_key eq 'mlb'))
{
  my $new_count = 0;
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
      $new_count++;
    };
    if ($@)
    {
      print "ERROR: $@\n";
      $dbh->rollback();
    }
  }

  $sth_insert_player->finish();
  print "Inserted $new_count new players\n";
  print ERIK "Inserted $new_count new players\n";
}

$dbh->disconnect();
close(ERIK);

print "DONE\n";
