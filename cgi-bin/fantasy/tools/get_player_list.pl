#!/usr/bin/perl

use strict;
use LWP::UserAgent;

use lib qw(../);
use DBTools;

##if (@ARGV < 1)
##{
##  print "Usage: $0 sport\n\n";
##  exit(0);
##}

## DB connection/queries
my $dbh = dbConnect();

print "Content-type: text/html\n\n";

##my $sport = lc($ARGV[0]);
my $sport = 'football';
my $sport_tag;
my $max;
if ($sport eq 'football')
{
  $sport_tag = 'ffl';
  $max = 541;
}
elsif ($sport eq 'baseball')
{
  $sport_tag = 'flb';
  $max = 901;
}
else
{
  print "'sport' must be 'football' or 'baseball'!\n";
  exit(0);
}

##my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) = checkSession();

##my $sth_check = $dbh->prepare("select count(1) from players where sport='$sport' and name=?");
my $sth_check = $dbh->prepare("select team from players where sport='$sport' and name=?");
my $sth_update = $dbh->prepare("update players set position=?, team=?, rank=? where sport='$sport' and name=?");
my $sth_update_by_team = $dbh->prepare("update players set position=?, rank=? where sport='$sport' and name=? and team=?");
my $sth_insert = $dbh->prepare("insert into players (name,sport,position,team,rank) values (?,'$sport',?,?,?)");


my $count = 0;
my $count_incr = 15;
my $wget_cmd = '/usr/local/bin/wget';
open(OUT,">${sport}_players.txt");
open(LOG,">${sport}_log.txt");

my $url = '';
my $content = '';
my $tagline = '';
my $index = 0;
my $search_page = './PLAYER_PAGE';
my $ua = LWP::UserAgent->new;

## Get player pages, 25 players per page, until pages are empty (will exit from inside loop)
while ($count <= $max)
{
  $url = "http://games.espn.go.com/${sport_tag}/tools/projections?display=alt&start=1&startIndex=${count}";
  ##$url = "http://games.espn.go.com/${sport_tag}/tools/projections?start=${count}";
  ##my $status = system("$wget_cmd '$url' -q -O $search_page");
  my $response = $ua->get($url, ':content_file'  => $search_page);

  ## Get the page data for each player rank
  for (my $x = ($count+1); $x <= ($count + $count_incr); $x++)
  {
    my @data = ();
    my $player = '';
    my $team = '';
    my $pos = '';

    ##$tagline = "<td align=\"right\">${x}</td><td><nobr><div league_id";
    ##$tagline = "<td align=\"left\" width=\"162\"><nobr>$x\. <div";
    $tagline = "subheadPlayerNameLink\"><nobr>${x}\. ";
    $content = `grep -i '$tagline' $search_page`;
    $content =~ s/.*${tagline}//;
    if ($content =~ m/>([a-zA-Z\.\-\']+ [a-zA-Z.-]+[ a-zA-Z\.\-\'\/]*)</ )
    {
      $player = $1;
    }
    else
    {
      print LOG "Cannot find a name entry for Player Ranked $x  '$tagline' ($content)!\n";
      next;
    }
    
    if ($player =~ /([a-zA-Z]+) D\/ST/ )
    {
      $player = $1;
      $pos = "DEF";
      if ($content =~ m/>[\*]?, ([A-Za-z]{2,3})</ )
      {
        $team = $1;
      }
      else
      {
        print LOG "No TEAM found for $player, $pos\n";
        next;
      }
    }
    elsif ($content =~ m/>[\*]?\, ([A-Za-z]{2,3} [0-9]?[a-zA-Z]{1,2}).*</)
##    elsif ($content =~ m/\, ([A-Za-z]{2,3, [0-9]?[a-zA-Z]{1,2})</ )
    {
      @data = split(/ /, $1);
      $team = $data[0];
      for (my $y = 1; $y < @data; $y++)
      {
        $data[$y] =~ s/,//g;
        $pos .= "$data[$y]|";
      }
      chop($pos);
    }
    else
    {
      print LOG "Cannot find team/pos info for $player!\n";
      next;
    }
    $team =~ s/,//g;
    print OUT "$player;$pos;$team;$x\n";

    $sth_check->execute($player);
     my $player_teams = $sth_check->fetchall_arrayref();
    $sth_check->finish();
    if (@{$player_teams} > 1)
    {
      print LOG "ERROR! Found " . @{$player_teams} . " entries for $sport player $player!\n";
      
      ## Check if any of these multiple entries is the same team as our player update entry
      my $team_found = 0;
      foreach my $t (@{$player_teams})
      {
        if ($t->[0] eq $team)
        {
          print LOG "\tMatched scraped team '$team' to a DB entry!\n";
          print LOG "UPDATE: $pos,$team,$x,$player\n";
          $sth_update_by_team->execute($pos,$x,$player,$team);
          $team_found = 1;
          last;
        }
      }
      if (! $team_found)
      {
        print LOG "\tUnable to match to any existing player entry - Manually FIX!\n";
        next;
      }
    }
    elsif (@{$player_teams} == 1)
    {
      $sth_update->execute($pos,$team,$x,$player);
      print LOG "UPDATE: $pos,$team,$x,$player\n";
    }
    else
    {
      $sth_insert->execute($player,$pos,$team,$x);
      print LOG "INSERT $player;$pos;$team;$x\n";
    }
    
  }
 
  $count += $count_incr;
} # end while($count <= $max)

## Final commit and close DB items
$sth_insert->finish();
$sth_update->finish();
$dbh->disconnect();

## Close output files
close(OUT);
close(LOG);


## Remove the temporary web-content file
system("rm -f $search_page");


print "ALL DONE!";