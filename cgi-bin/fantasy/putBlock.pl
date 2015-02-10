#!/usr/bin/perl

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use CGI ':cgi-lib';

use Session;
use DBTools;

my $query = new CGI();

# files
my ($my_ip,$user,$pswd,$my_id,$team_t,$sport_t,$league_t) = checkSession();
my $dbh = dbConnect();

#Get League Data
$sth = $dbh->prepare("SELECT * FROM leagues WHERE name = '$league_t'")
         or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
($league_name,$password,$league_owner,$league_draftType,$draftStatus,$contractStatus,$sport,$categories,$league_positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
$sth->finish();


my %players;
my $params = $query->Vars;
foreach my $param (sort keys %$params)
{
  if ($param =~ /^select_(\d+)$/)
  {
    $players{$1} = -1;
  }

  if ($param =~ /^target_(\d+)$/)
  {
    $players{$1} = $params->{$param} if (defined $players{$1});
  }
}

my $addTradeBlock = $dbh->prepare("INSERT INTO trading_block VALUES (?, '$league_name', ?, '$team_t')");
foreach my $player (keys %players)
{
    next if($players{$player} <= 0);
    
    $addTradeBlock->execute($player,$players{$player});
}
dbDisconnect($dbh);

$return = "/cgi-bin/fantasy/getBlock.pl";
print "Location: $return\n\n";
