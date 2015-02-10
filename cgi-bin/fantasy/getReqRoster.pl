#!/usr/bin/perl
# script to check current bids on the fly
use DBI;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use Leagues;
use DBTools;
use strict;

## For UTF-8 characters
binmode(STDOUT, ":utf8");

my ($string1, $string2) = split('=',$ENV{'QUERY_STRING'});
$string2 =~ s/%20/ /g;
my ($players_won_file, $owner_t, $league_t) = split(';',$string2);
##my $players_won_file = "players_won";
my $players_file = "players";

my $return_string = " ";
my $roster_string = " ";
my %players;

open (LOG,">getReqRoster_LOG.out");

my $dbh = dbConnect();

#Get League Data
##($league_name,$password,$owner,$draftType,$draftStatus,$contractStatus,$sport,$categories,$positions,$max_members,$cap,$auction_length,$bid_time_extension,$bid_time_buffer,$TZ_offset,$login_extend_time,$use_IP_flag,$contractA,$contractB,$contractC,$keeper_increase,$keeper_prices) = $sth->fetchrow_array();
#Get League Data
my $league = Leagues->new($league_t,$dbh);
if (! defined $league)
{
  die "ERROR - league object not found!\n";
}

my $sport = $league->sport();
my @pos_array = ();
if ($sport eq "baseball")
{
   @pos_array = ('C','1B','2B','3B','SS','OF','SP','RP'); 
}
if ($sport eq "football")
{
   @pos_array = ('QB','RB','RB2','WR','WR2','TE','K','DEF');
}

foreach my $pos (@pos_array)
{
  $league->{_POSITIONS}->{$pos} = 1;
}

my $sth_roster = $dbh->prepare("select position from positions where league='$league_t'");
$sth_roster->execute();
while ( my $pos = $sth_roster->fetchrow() )
{
   # Add user-selected positions
   push(@pos_array,$pos);
}
$sth_roster->finish();


foreach my $pos (@pos_array)
{
  print LOG "Applied position $pos\n";
  $players{$pos}->{NAME} = ' ';
  $players{$pos}->{COST} = ' ';
}

## Get the team name for this owner
my $sth = $dbh->prepare("SELECT * FROM teams WHERE owner = '$owner_t' AND league = '$league_t'")
        or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
 my ($tf_owner,$saved_team_name,$tf_league,$tf_adds,$tf_sport,$tf_plusminus) = $sth->fetchrow_array();
$sth->finish();


$sth = $dbh->prepare("SELECT w.name,w.price,w.team,w.time,p.name,p.position FROM $players_won_file w, $players_file p WHERE w.league = '$league_t' and w.team='$saved_team_name' and w.name=p.playerid order by p.rank")
       or die "Cannot prepare: " . $dbh->errstr();

my $sth_get_name = $dbh->prepare("SELECT name,position FROM $players_file WHERE playerid=?")
                   or die "Cannot prepare: " . $dbh->errstr();

my $year_limit = ($players_won_file eq 'players_won') ? -2 : 0;
my $year_limit = -2;
my %contractids;
my $sth_get_contracts = $dbh->prepare("select player, years_left from contracts where league='$league_t' and broken='N' and (locked='yes' OR (years_left < total_years)) and years_left>$year_limit");
$sth_get_contracts->execute();
 while (my ($contractid, $years) = $sth_get_contracts->fetchrow_array())
 {
   $contractids{$contractid} = ($players_won_file eq 'players_won') ? 1 : $years;
 }
$sth_get_contracts->finish();

## Also get franchise/transition tags
my $sth_get_tags = $dbh->prepare("select player from tags where league='$league_t' and locked='yes' and active='no'");
$sth_get_tags->execute();
 while (my $tagid = $sth_get_tags->fetchrow())
 {
   $contractids{$tagid} = ($players_won_file eq 'players_won') ? 1 : -1;
 }
$sth_get_tags->finish();


my $money_left = $league->{_SALARY_CAP} + $tf_plusminus;
my $sth_rels = $dbh->prepare("select rel_position from position_relations where position=?");
my $sth_check_pos = $dbh->prepare("select position from positions where league='$league_t' and position like ?");

$sth->execute() or die "Cannot execute: " . $sth->errstr();
while (my ($id,$bid,$bidder,$ez_time,$name,$pos) = $sth->fetchrow_array())
{
   ## Keeper tag for this player
   my $keeper_flag;
   if (! defined $contractids{$id}) { $keeper_flag = 0; }
   else { $keeper_flag = ($contractids{$id} > 0) ? 1 : -1; }

   #player is on this team, assign to a position
   if ($bidder eq $saved_team_name)
   {
      # Keep track of how much money the owner has left
      $money_left -= $bid;

      $sth_rels->execute($pos);
      $sth_check_pos->execute("$pos%");
      while (my $checkpos = $sth_check_pos->fetchrow() )
      {
        $pos .= "/$checkpos";
      }

      while (my $relpos = $sth_rels->fetchrow() )
      {
        $sth_check_pos->execute("$relpos%");
        while (my $checkpos = $sth_check_pos->fetchrow() )
        {
          $pos .= "/$checkpos";
        }
      }
      

      ##Add Bench spots
      $sth_check_pos->execute("B%");
      while (my $checkpos = $sth_check_pos->fetchrow() )
      {
        $pos .= "/$checkpos";
      }

      my $player_assigned = 0;
      my @temp_pos = split('/', $pos);
      foreach (@temp_pos)
      {
        # If this position is in the league and is not taken, assign it to this player
        if ($league->{_POSITIONS}->{$_})
        {
          if ($players{$_}->{NAME} !~ /\w/)
          {
            $players{$_}->{NAME} = "$id|$name|$keeper_flag";
            $players{$_}->{COST} = "$bid";
            last;
          }
        }
      }


    } #end if ($bidder eq $saved_team_name)

} # end while loop

$sth->finish();


#Reorder Roster Info
foreach my $pos (keys %players)
{
  if ($players{$pos}->{NAME} =~ /\w/)
  {
    $roster_string .= "," . $players{$pos}->{NAME} . ":$pos:" . $players{$pos}->{COST};
  }
  else
  {
    $roster_string .= ",-1|<b>EMPTY</b>|0:$pos:0";
  }
}

## ECW TODO -add anyone who missed position assignment?


# Get owner Email info
my $table = "passwd";
$sth = $dbh->prepare("SELECT email FROM $table WHERE name = '$owner_t'")
        or die "Cannot prepare: " . $dbh->errstr();
$sth->execute() or die "Cannot execute: " . $sth->errstr();
my $owner_email = $sth->fetchrow();

$sth->finish();
dbDisconnect($dbh);


$return_string = "$owner_t/$saved_team_name:$owner_email:$money_left:$sport;$roster_string";

close(LOG);

print "Content-type: text/html\n\n";
print "$return_string;";
