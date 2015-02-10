#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::Cookie;
use POSIX qw(ceil floor);
use DBTools;
use Session;
use Data::Dumper;

my $cgi = new CGI;

#variables that will be used later.

$errors = "/var/log/fantasy/create_league_errors2.txt";
$log = "/var/log/fantasy/LOG.txt";

$return = "/fantasy/fantasy_main_index.htm";
$errorflag = 0;

open (FILE, ">$errors");
 flock(FILE,2);
 print FILE "\n";
close(FILE);

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
$in_leagueName = $cgi->param('leagueName');
$in_leaguePassword = $cgi->param('leaguePassword');
$in_teamName = $cgi->param('teamName');
$in_max_members = $cgi->param('max_members');
$in_draftType = $cgi->param('draftType');
$in_keeper = $cgi->param('Keeper');
$in_keeper_leagueName = $cgi->param('keeper_leagueName');
$in_keeper_leaguePassword = $cgi->param('keeper_leaguePassword');
$in_keeper_name_persist = $cgi->param('keeper_name_persist');
$in_salary_cap = $cgi->param('salary_cap');
$in_sport = $cgi->param('sport');

# Keeper parameters
my %fa_costs;
my %contracts;
$import_contracts = $cgi->param('import_contracts');
if ($import_contracts eq 'yes')
{
  $contract_count = $cgi->param('contract_count');
  $keeper_increase = $cgi->param('keeper_increase');
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

my ($ip, $user, $password, $sess_id, $team_t, $sport_t, $league_t) = checkSession();

my $dbh = dbConnect();

## Make sure that the owner has filled out all fields
if ($in_max_members =~ /^$/)
{
  open (FILE,">>$errors");
  flock(FILE,2);
  print FILE "$userAddr;$user;<b>Please enter a value for Maximum League Members!</b>\n";
  close(FILE);
  $errorflag = 1;
}

if (($in_draftType eq "auction") && ($in_salary_cap =~ /^$/))
{
   open (FILE, ">>$errors");
   flock(FILE,2);
   print FILE "$userAddr;$user;<b>Please provide a salary cap!</b>\n";
   close(FILE);
   $errorflag = 1;
}

if ($in_keeper eq "yes")
{
  if (keys(%contracts) < 1)
  {
     open (FILE, ">>$errors");
     flock(FILE,2);
     print FILE "$userAddr;$user;<b>You must enter keeper contract parameters!</b>\n";
     close(FILE);
     $errorflag = 1;
   }
   if ($keeper_increase =~ /^$/)
   {
     open (FILE, ">>$errors");
     flock(FILE,2);
     print FILE "$userAddr;$user;<b>You must enter keeper increase percentage!</b>\n";
     close(FILE);
     $errorflag = 1;
   }
   elsif (($keeper_increase < 0) || ($keeper_increase > 100))
   {
     open (FILE, ">>$errors");
     flock(FILE,2);
     print FILE "$userAddr;$user;<b>You must enter a valid keeper increase percentage (0-100)!</b>\n";
     close(FILE);
     $errorflag = 1;
   }
   foreach my $pos (%fa_prices)
   {
     if (! defined $fa_prices{$pos})
     {
       open (FILE, ">>$errors");
       flock(FILE,2);
       print FILE "$userAddr;$user;<b>You must enter FA/Waiver prices for all positions! ($pos is empty)</b>\n";
       close(FILE);
       $errorflag = 1;
     }
   }
}

if ($errorflag != 1)
{

  $in_salary_cap = 0 if ($in_draftType ne 'Auction');
  $keeper_increase = 1 + ($keeper_increase/100);

  # update leagues database
  $sth = $dbh->prepare("INSERT INTO leagues (name,password,owner,draft_type,draft_status,keepers_locked,sport,max_teams,salary_cap,auction_length,bid_time_ext,bid_time_buff,tz_offset,login_ext,sessions_flag,keeper_increase) VALUES('$in_leagueName','$in_leaguePassword','$user','$in_draftType','open','no','$in_sport','$in_max_members','$in_salary_cap','20','5','8','0','180','yes','$keeper_increase')") or die "Cannot prepare: " . $dbh->errstr();
  $sth->execute() or die "Cannot execute: " . $sth->errstr();
  $sth->finish();
  

  ##update categories
  $sth_inserts=$dbh->prepare("insert into categories VALUES ('$in_leagueName',?)");
  foreach my $cat (@{$categories_offered{$in_sport}})
  {
    if (defined $cgi->param("$cat"))
    {
      $sth_inserts->execute($cat);
    }
  }
  $sth_inserts->finish();


  ##update positions
  $sth_inserts=$dbh->prepare("insert into positions VALUES ('$in_leagueName',?)");
  foreach my $pos (@{$pos_offered{$in_sport}})
  {
    if (defined $cgi->param("$pos"))
    {
      $sth_inserts->execute($pos);
    }
  }
  $sth_inserts->finish();


  if ($in_keeper eq 'yes')
  {
    ##update fa_keeper prices
    $sth_inserts=$dbh->prepare("insert into fa_keepers VALUES ('$in_leagueName',?,?)");
    foreach my $pos (keys %fa_costs)
    {
      $sth_inserts->execute($pos, $fa_costs{$pos});
    }
    $sth_inserts->finish();


    ##update keeper slots (contracts available)
    $sth_inserts=$dbh->prepare("insert into keeper_slots VALUES ('$in_leagueName',?,?,?)");
    foreach my $type (keys %contracts)
    {
      $sth_inserts->execute($contracts{$type}->{MIN},$contracts{$type}->{MAX},$contracts{$type}->{NUM});
    }
    $sth_inserts->finish();
  }

  # If the new league is a keeper-continuation, import the same teams into teams table, and the kept players into players_won
  if ($import_contracts eq 'yes')
  {
    my %owner_penalties;
    
    ## ECW - known bug! If a player in a multi-year contract is dropped during the season, from the queries below he will still be imported into the next season. We need to have them break the contract ... maybe in the import-rosters script?
    $sth1 = $dbh->prepare("Select c.player,c.team,c.total_years,c.years_left,c.current_cost,c.league,c.locked,c.broken,c.penalty,t.name,p.position from contracts c, teams t, players p where c.league = '$in_keeper_leagueName' and c.years_left>0 and c.league=t.league and t.owner=c.team and p.playerid=c.player") or die "Cannot prepare: " . $dbh->errstr();
    $sth5 = $dbh->prepare("Select g.player,g.team,g.type,g.league,g.cost,g.locked,g.active,t.name from tags g, teams t, players p where g.league = '$in_keeper_leagueName' and g.league=t.league and t.owner=g.team and p.playerid=g.player and g.type='F' and g.active='yes'") or die "Cannot prepare: " . $dbh->errstr();
    $sth2 = $dbh->prepare("INSERT INTO players_won (name, price, team, league) VALUES (?,?,?,'$in_leagueName')") or die "Cannot prepare: " . $dbh->errstr();    
    $sth3 = $dbh->prepare("insert into contracts (player,team,total_years,years_left,current_cost,league,locked) values (?,?,?,?,?,?,?)");
    $sth4 = $dbh->prepare("update contracts set locked='yes' where league='$in_leagueName'");
    $sth6 = $dbh->prepare("insert into tags (player,team,type,league,cost,locked,active) values (?,?,?,?,?,?,?)");
    $sth7 = $dbh->prepare("update tags set locked='yes' where league='$in_leagueName'");

    ## Assure that all contracts & tags for this league are now locked. Officially, it won't matter ... but cheers to consistency
    $sth4->execute();
    $sth7->execute();
    $sth4->finish();
    $sth7->finish();

    ## ECW TODO
    ## Franchise Tag insertions - TBD needs work!
    $sth5->execute() or die "Cannot execute: " . $sth5->errstr();
    while (($t_player,$t_owner,$t_type,$t_league,$t_cost,$t_locked,$t_active,$team_name) = $sth5->fetchrow_array())
    {
      ## Insert this player into the players_won table for the new season
      if (($t_owner eq $user) & ($in_keeper_name_persist ne 'yes'))
      {
        $sth2->execute($t_player,$t_cost,$in_teamName) or die "Cannot execute: " . $sth2->errstr();
      }
      else
      {
        $sth2->execute($c_player,$t_cost,$t_team) or die "Cannot execute: " . $sth2->errstr();
      }

      $sth6->execute($t_player,$t_owner,$t_type,$in_leagueName,$t_cost,$t_locked,'no');
    }
    
    $sth1->execute() or die "Cannot execute: " . $sth1->errstr();
    while (($c_player,$c_owner,$c_total_years,$c_years_left,$c_cost,$c_league,$c_locked,$c_broken,$c_penalty,$t_team,$p_pos) = $sth1->fetchrow_array())
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
        my $p_pos = $1 if ($p_pos =~ m/(.*)\|.*/);
        $p_pos = $1 if ($p_pos =~ m/(.*)\/.*/);

        $new_price = -99; ## Error catching code for bad positions
        $new_price = $fa_costs{$p_pos} if (defined $fa_costs{$p_pos});
      }

      ## Else, this was a player with an initial cost (from draft or previous keeper contract)
       # Bump him up by the league's keeper increase, and do the correct rounding
      else 
      {
        ## If this is an existing keeper, make sure to bump up the price per league specs
        $new_price *= $keeper_increase;

        if ($new_price < 10)
        {
          ($main, $dec) = split(/\./,$new_price);
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
      if (($c_owner eq $user) & ($in_keeper_name_persist ne 'yes'))
      {
        $sth2->execute($c_player,$new_price,$in_teamName) or die "Cannot execute: " . $sth2->errstr();
      }
      else
      {
        $sth2->execute($c_player,$new_price,$t_team) or die "Cannot execute: " . $sth2->errstr();
      }

      ## Insert a new contract entry for this player
      $c_years_left--;
      $c_years_left = -1 if ($c_years_left == 0);
      $sth3->execute($c_player,$c_owner,$c_total_years,$c_years_left,$new_price,$in_leagueName,'yes');
    }
    $sth1->finish();
    $sth2->finish();
    $sth3->finish();
    
    
    $sth1 = $dbh->prepare("Select owner, name, sport from teams where league = '$in_keeper_leagueName'") or die "Cannot prepare: " . $dbh->errstr();
    $sth2 = $dbh->prepare("INSERT INTO teams VALUES (?,?,'$in_leagueName',0,'$in_sport',?)") or die "Cannot prepare: " . $dbh->errstr();
    $sth1->execute() or die "Cannot execute: " . $sth1->errstr();
    while (($t_owner,$t_name,$t_sport) = $sth1->fetchrow_array())
    {
      ## Get any broken-contract penalties, if applicable
      my $penalty = $owner_penalties{$t_owner} * -1;
      $penalty = 0 if (! defined $penalty);
      
      if (($t_owner eq $user) & ($in_keeper_name_persist ne 'yes'))
      {
        $sth2->execute($t_owner,$in_teamName,$penalty);
      }
      else
      {
        $sth2->execute($t_owner,$t_name,$penalty) or die "Cannot execute: " . $sth2->errstr();
      }
    }
    $sth1->finish();
    $sth2->finish();


  }
  else
  {
    # Add this team/league pairing to the teams db
    $sth = $dbh->prepare("INSERT INTO teams VALUES('$user','$in_teamName','$in_leagueName','0','$in_sport',0)") or die "Cannot prepare: " . $dbh->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    $sth->finish();
  }

  open (FILE, ">>$errors");
  flock(FILE,1);
  print FILE "$userAddr;$user;<b>League <i>$in_leagueName</i> has been created!</b>\n";
  close(FILE);  

  #
  #create data files for the new league
  #
  open(FILE,"/var/log/fantasy/trades_$in_leagueName.txt");
  flock(FILE,1);
  print FILE "";
  close(FILE);

  open(FILE,"/var/log/fantasy/trade_messages_$in_leagueName.txt");
  flock(FILE,1);
  print FILE "";
  close(FILE);

  open(FILE,"/var/log/fantasy/player_targets_$in_leagueName.txt");
  flock(FILE,1);
  print FILE "";
  close(FILE);

  $return = "/fantasy/fantasy_main_index.htm";
}

dbDisconnect($dbh);
print "Location: $return\n\n";
