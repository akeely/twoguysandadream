#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use POSIX qw(ceil floor);
use DBTools;
use Session;
use Data::Dumper;
use strict;

my $cgi = new CGI;

#variables that will be used later.

my $log = "/var/log/fantasy/LOG.txt";

my $return = "/fantasy/fantasy_main_index.htm";
my $errorflag = 0;

open(LOG,">$log");
print LOG Dumper($cgi);
close(LOG);

my %categories_offered;
$categories_offered{baseball} = ['H','R','RBI','ST','CS','AVG','OBP','HR','TB',
                  'OffK','IP','W','L','PitK','SV','CG','SHO','ERA','WHIP','KBB'];
$categories_offered{football} = ['PassTD','PassY','OINT','RunTD','RunY','RecTD',
              'RecY','Rec','RetY','RetTD','FG','FGmiss','XP','XPmiss','TwoP','Fum',
                    'Sack','DINT','FumRec','DefTD','Safe','Block','PtsAll','Pen'];

## This list of positions includes only EXTRA positions, so not the essentials (QB, RB, 1B, C, etc)
my %pos_offered;
$pos_offered{baseball} = ['Util','Util2','Util3','Util_IN','Util_OF','SP2','SP3','OF2','OF3',
                    'RP2','RP3','P1','P2','P3','B1','B2','B3','B4','B5','B6','B7','B8','B9'];
$pos_offered{football} = ['RB2','RB3','WR2','WR3','OFF1','OFF2',
                                  'QB2','QB3','K2','TE2','DEF2','B1','B2','B3','B4','B5','B6','B7','B8','B9'];
             

## Input Variables
my $in_leagueName = $cgi->param('leagueName');
my $in_leaguePassword = $cgi->param('leaguePassword');
my $in_teamName = $cgi->param('teamName');
my $in_max_members = $cgi->param('max_members');
my $in_draftType = $cgi->param('draftType');
my $in_keeper = $cgi->param('Keeper');
my $in_keeper_leagueName = $cgi->param('keeper_leagueName') || '';
my $in_keeper_leaguePassword = $cgi->param('keeper_leaguePassword');
my $in_keeper_name_persist = $cgi->param('keeper_name_persist');
my $in_salary_cap = $cgi->param('salary_cap');
my $in_sport = $cgi->param('sport');


# Keeper parameters
my $contract_count = $cgi->param('contract_count');
my $keeper_increase = $cgi->param('keeper_increase');
my %fa_costs;
my %contracts;
my $import_contracts = $cgi->param('import_contracts');
if ($import_contracts eq 'yes')
{
  if ($in_sport eq 'baseball')
  {
    $fa_costs{'C'} = $cgi->param('C_price');
    $fa_costs{'1B'} = $cgi->param('1B_price');
    $fa_costs{'2B'} = $cgi->param('2B_price');
    $fa_costs{'3B'} = $cgi->param('3B_price');
    $fa_costs{'SS'} = $cgi->param('SS_price');
    $fa_costs{'OF'} = $cgi->param('OF_price');
    $fa_costs{'DH'} = $cgi->param('DH_price');
    $fa_costs{'SP'} = $cgi->param('SP_price');
    $fa_costs{'RP'} = $cgi->param('RP_price');
  }
  elsif ($in_sport eq 'football')
  {
    $fa_costs{'QB'} = $cgi->param('QB_price');
    $fa_costs{'RB'} = $cgi->param('RB_price');
    $fa_costs{'WR'} = $cgi->param('WR_price');
    $fa_costs{'TE'} = $cgi->param('TE_price');
    $fa_costs{'K'} = $cgi->param('K_price');
    $fa_costs{'DEF'} = $cgi->param('DEF_price');
  }

  for(my $x=1; $x<=$cgi->param('contract_count'); $x++)
  {
    $contracts{$x}->{MIN} = $cgi->param("c_min_$x");
    $contracts{$x}->{MAX} = $cgi->param("c_max_$x");
    $contracts{$x}->{NUM} = $cgi->param("c_num_$x");
  }
}

my ($ip,$sess_id,$sport_t,$leagueid, $teamid, $ownerid, $ownername, $teamname) = checkSession();

my $dbh = dbConnect();


if ($in_keeper eq "yes")
{
  if (keys(%contracts) < 1)
  {
    $errorflag = 1;
  }
  if ($keeper_increase =~ /^$/)
  {
    $errorflag = 1;
  }
  elsif (($keeper_increase < 0) || ($keeper_increase > 100))
  {
    $errorflag = 1;
  }
  foreach my $pos (keys %fa_costs)
  {
    if (! defined $fa_costs{$pos})
    {
      $errorflag = 1;
    }
  }

  my $sth_league_check = $dbh->prepare("select id from leagues where name='$in_keeper_leagueName'");
  $sth_league_check->execute();
  $leagueid = $sth_league_check->fetchrow();
  
  if (!defined $leagueid) {
    $errorflag = 1;
  }
}

if ($errorflag != 1)
{


  $in_salary_cap = 0 if ($in_draftType ne 'Auction');
  $keeper_increase = 1 + ($keeper_increase/100);

  # update leagues database
  my $sth_insert_league = $dbh->prepare("INSERT INTO leagues (name,password,ownerid,draft_type,draft_status,keepers_locked,sport,max_teams,salary_cap,auction_length,bid_time_ext,bid_time_buff,tz_offset,login_ext,sessions_flag,keeper_increase, previous_league) VALUES('$in_leagueName','$in_leaguePassword',$ownerid,'$in_draftType','open','no','$in_sport','$in_max_members','$in_salary_cap','20','5','8','0','180','yes','$keeper_increase','$in_keeper_leagueName')") or die "Cannot prepare: " . $dbh->errstr();
  $sth_insert_league->execute() or die "Cannot execute: " . $sth_insert_league->errstr();
  $sth_insert_league->finish();

  my $new_leagueid = $dbh->last_insert_id(undef, undef, 'leagues', 'id');

  ##update categories
  my $sth_insert_cats=$dbh->prepare("insert into categories (category, leagueid) VALUES (?, $new_leagueid)");
  foreach my $cat (@{$categories_offered{$in_sport}})
  {
    if (defined $cgi->param("$cat"))
    {
      $sth_insert_cats->execute($cat);
    }
  }
  $sth_insert_cats->finish();


  ##update positions
  my $sth_insert_positions=$dbh->prepare("insert into positions (position, leagueid) VALUES (?, $new_leagueid)");
  foreach my $pos (@{$pos_offered{$in_sport}})
  {
    if (defined $cgi->param("$pos"))
    {
      $sth_insert_positions->execute($pos);
    }
  }
  $sth_insert_positions->finish();


  if ($in_keeper eq 'yes')
  {
    ##update fa_keeper prices
    my $sth_insert_fa_prices=$dbh->prepare("insert into fa_keepers (position, price, leagueid) VALUES (?,?, $new_leagueid)");
    foreach my $pos (keys %fa_costs)
    {
      $sth_insert_fa_prices->execute($pos, $fa_costs{$pos});
    }
    $sth_insert_fa_prices->finish();


    ##update keeper slots (contracts available)
    my $sth_insert_keeper_slots=$dbh->prepare("insert into keeper_slots (min, max, number, leagueid) VALUES (?,?,?,$new_leagueid)");
    foreach my $type (keys %contracts)
    {
      $sth_insert_keeper_slots->execute($contracts{$type}->{MIN},$contracts{$type}->{MAX},$contracts{$type}->{NUM});
    }
    $sth_insert_keeper_slots->finish();
  }

  # If the new league is a keeper-continuation, import the same teams into teams table, and the kept players into players_won
  if ($import_contracts eq 'yes')
  {

    ## get a mapping of existing teamIds to new teamIds
    my %owner_team_map;
    my $sth_team_select = $dbh->prepare("Select ownerid, name from teams where leagueid = $leagueid") or die "Cannot prepare: " . $dbh->errstr();
    my $sth_insert_new_team = $dbh->prepare("INSERT INTO teams (name, num_adds, sport, money_plusminus, ownerid, leagueid) VALUES(?,0,'$in_sport',0, ?, $new_leagueid)");
    $sth_team_select->execute() or die "Cannot execute: " . $sth_team_select->errstr();
    while (my ($t_owner, $t_name) = $sth_team_select->fetchrow_array())
    {
      
      if (($t_owner eq $ownerid) && ($in_keeper_name_persist ne 'yes'))
      {
        $sth_insert_new_team->execute($in_teamName,$t_owner);
      }
      else
      {
        $sth_insert_new_team->execute($t_name,$t_owner) or die "Cannot execute: " . $sth_insert_new_team->errstr();
      }

      my $new_teamid = $dbh->last_insert_id(undef, undef, 'teams', 'id');
      $owner_team_map{$t_owner} = $new_teamid;


    }
    $sth_team_select->finish();
    $sth_insert_new_team->finish();


    ## ECW - known bug! If a player in a multi-year contract is dropped during the season, from the queries below he will still be imported into the next season. We need to have them break the contract ... maybe in the import-rosters script?
    my $sth_select_contracts = $dbh->prepare("Select c.playerid,c.ownerid,c.total_years,c.years_left,c.current_cost,c.leagueid,c.locked,c.broken,c.penalty,p.position from contracts c, teams t, players p where c.leagueid = $leagueid and c.years_left>0 and c.leagueid=t.leagueid and t.ownerid=c.ownerid and p.playerid=c.playerid") or die "Cannot prepare: " . $dbh->errstr();
    my $sth_select_tags = $dbh->prepare("Select g.playerid,g.ownerid,g.type,g.leagueid,g.cost,g.locked,g.active from tags g, teams t, players p where g.leagueid = $leagueid and g.leagueid=t.leagueid and t.ownerid=g.ownerid and p.playerid=g.playerid and g.type='F' and g.active='yes'") or die "Cannot prepare: " . $dbh->errstr();
    my $sth_insert_new_league_players = $dbh->prepare("INSERT INTO players_won (playerid, price, teamid, leagueid, time) VALUES (?,?,?,$new_leagueid, ?)") or die "Cannot prepare: " . $dbh->errstr();    
    my $sth_insert_new_league_contracts = $dbh->prepare("insert into contracts (playerid,ownerid,total_years,years_left,current_cost,leagueid,locked) values (?,?,?,?,?,?,?)");
    my $sth_lock_old_contracts = $dbh->prepare("update contracts set locked='yes' where leagueid=$new_leagueid");
    my $sth_insert_new_league_tags = $dbh->prepare("insert into tags (playerid,ownerid,type,leagueid,cost,locked,active) values (?,?,?,?,?,?,?)");
    my $sth_lock_old_tags = $dbh->prepare("update tags set locked='yes' where leagueid=$new_leagueid");

    ## Assure that all contracts & tags for this league are now locked. Officially, it won't matter ... but cheers to consistency
    $sth_lock_old_contracts->execute();
    $sth_lock_old_tags->execute();
    $sth_lock_old_contracts->finish();
    $sth_lock_old_tags->finish();

    $sth_select_tags->execute() or die "Cannot execute: " . $sth_select_tags->errstr();
    while (my ($t_player,$t_owner,$t_type,$t_league,$t_cost,$t_locked,$t_active) = $sth_select_tags->fetchrow_array())
    {
      ## Insert this player into the players_won table for the new season
      $sth_insert_new_league_players->execute($t_player,$t_cost,$owner_team_map{$t_owner}, 'FRANCHISE TAG') or die "Cannot execute: " . $sth_insert_new_league_players->errstr();

      ## Insert row into the tags table for the new season
      $sth_insert_new_league_tags->execute($t_player,$t_owner,$t_type,$new_leagueid,$t_cost,$t_locked,'no');
    }
    
    my %owner_penalties;
    $sth_select_contracts->execute() or die "Cannot execute: " . $sth_select_contracts->errstr();
    while (my ($c_player,$c_owner,$c_total_years,$c_years_left,$c_cost,$c_league,$c_locked,$c_broken,$c_penalty,$p_pos) = $sth_select_contracts->fetchrow_array())
    {
      ## If this is a broken contract, record the penalty amount to reflect against the owner's cap, then skip it (not importing to new league)
      if ($c_broken eq 'Y')
      {
        $owner_penalties{$c_owner} += $c_penalty;
        next;
      }
      
      my $new_price = $c_cost;

      ## If the player cost is 0, he was a FA pickup. Apply the league's default position pricing
      if ($new_price == 0)
      {
        ## Only use a single position - remove multiples if they exist
        $p_pos = $1 if ($p_pos =~ m/(.*?)\|.*/);
        $p_pos = $1 if ($p_pos =~ m/(.*?)\/.*/);

        $new_price = -99; ## Error catching code for bad positions
        $new_price = $fa_costs{$p_pos} if (defined $fa_costs{$p_pos});
      }

      ## Else, this was a player with an initial cost (from draft or previous keeper contract)
       # Bump him up by the league's keeper increase, and do the correct rounding
      else 
      {
        ## If this is an existing keeper, make sure to bump up the price per league specs
        $new_price *= $keeper_increase;

        my $cost2;
        if ($new_price < 10)
        {
          my ($main, $dec) = split(/\./,$new_price);
          my $dec2 = substr($dec, 0, 1);
          $cost2 = ceil($new_price);
          if (($dec2 <= 5) && (($dec2 > 0) || (($dec2 == 0) && (length($dec) == 2))))
          {
            $cost2 = $main . '.5';
            ## For the $0.50 players, need to make sure they are bumped up
            if ($cost2 == $c_cost)
            {
              $cost2 += 0.5;
            }
          }
        }
        else
        {
          $cost2 = ceil($new_price);
        }
        $new_price = $cost2;
      }

      ## Insert this player into the players_won table for the new season
      $sth_insert_new_league_players->execute($c_player,$new_price,$owner_team_map{$c_owner},'KEEPER CONTRACT') or die "Cannot execute: " . $sth_insert_new_league_players->errstr();

      ## Insert a new contract entry for this player
      $c_years_left--;
      $c_years_left = -1 if ($c_years_left == 0);
      $sth_insert_new_league_contracts->execute($c_player,$c_owner,$c_total_years,$c_years_left,$new_price,$new_leagueid,'yes');
    }
    $sth_select_contracts->finish();
    $sth_select_tags->finish();
    $sth_insert_new_league_players->finish();
    $sth_insert_new_league_contracts->finish();
    $sth_insert_new_league_tags->finish();

    ## update penalty amounts for new teams
    my $sth_update_team_penalties = $dbh->prepare("update teams set money_plusminus=? where id=?");
    foreach my $p_owner (keys %owner_penalties) {
      my $penalty = $owner_penalties{$p_owner} * -1;
      $sth_update_team_penalties->execute($penalty, $owner_team_map{$p_owner});
    }
    $sth_update_team_penalties->finish();

  }

  else
  {
    # Add this team/league pairing to the teams db
    my $sth = $dbh->prepare("INSERT INTO teams (name, num_adds, sport, money_plusminus, ownerid, leagueid) VALUES('$in_teamName',0,'$in_sport',0, $ownerid, $new_leagueid)") or die "Cannot prepare: " . $dbh->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    $sth->finish();
  }

  $return = "/fantasy/fantasy_main_index.htm";
}

dbDisconnect($dbh);
print "Location: $return\n\n";
