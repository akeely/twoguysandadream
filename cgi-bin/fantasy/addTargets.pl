#!/usr/bin/perl

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;

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

my $tableOwner = $query->param('owner');
if($tableOwner ne $user)
{
    $return = "/cgi-bin/fantasy/getTeam.pl";
    print "Location: $return\n\n";
    dbDisconnect($dbh);
    exit;
}

my @playerIDs = $query->param;

my $deleteOldTarget = $dbh->prepare("DELETE FROM targets WHERE playerID = ? AND owner = '$user' AND league = '$league_name'");
my $addTarget = $dbh->prepare("INSERT INTO targets VALUES (?, '$user', '$league_name', ?)");


foreach my $playerID (@playerIDs)
{
    next if($playerID !~ /^\d+$/);
    my $price = $query->param("$playerID");
    next if($price !~ /\d/);

    $deleteOldTarget->execute($playerID);
    $addTarget->execute($playerID,$price);
}

dbDisconnect($dbh);

$return = "/cgi-bin/fantasy/getTargets.pl";
print "Location: $return\n\n";
