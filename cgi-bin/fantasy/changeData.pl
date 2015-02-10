#!/usr/bin/perl
use Session;
use DBTools;

open(LOG, ">changeData.log");
$return_line='';

my %in_vars;
@values = split(/&/,$ENV{'QUERY_STRING'});
foreach $i (@values) {
  ($varname, $mydata) = split(/=/,$i);
  $mydata =~ s/%20/ /g;
print LOG "$varname=$mydata\n";
  $in_vars{$varname} = $mydata;
}

$dbh = dbConnect();

$real_owner = $in_vars{'real_owner'};

if (defined($in_vars{'email'}))
{
  $replacement = $in_vars{'email'};
  $sth = $dbh->prepare("update passwd set email='$replacement' WHERE name='$real_owner'");
  $sth->execute();
  $sth->finish();

  $return_line.="email=$replacement;";
}

if (defined($in_vars{'password'}))
{
  $replacement = $in_vars{'password'};
  $sth = $dbh->prepare("update passwd set passwd='$replacement' WHERE name='$real_owner'");
  $sth->execute();
  $sth->finish();

  $return_line.="password=$replacement;";
}

if (defined($in_vars{'team'}))
{
  $replacement = $in_vars{'team'};
  $real_league = $in_vars{'real_league'};

  $sth = $dbh->prepare("update auction_players set team='$replacement' where team=(select name from teams where owner='$real_owner' and league='$real_league') and league='$real_league'");
  $sth->execute();
  $sth->finish();

  $sth = $dbh->prepare("update players_won set team='$replacement' where team=(select name from teams where owner='$real_owner' and league='$real_league') and league='$real_league'");
  $sth->execute();
  $sth->finish();

  $sth = $dbh->prepare("update final_rosters set team='$replacement' where team=(select name from teams where owner='$real_owner' and league='$real_league') and league='$real_league'");
  $sth->execute();
  $sth->finish();

  $sth = $dbh->prepare("update sessions set team='$replacement' where owner='$real_owner' and league='$real_league'");
  $sth->execute();
  $sth->finish();

  $sth = $dbh->prepare("update targets set owner='$replacement' where owner=(select name from teams where owner='$real_owner' and league='$real_league') and league='$real_league'");
  $sth->execute();
  $sth->finish();

  ## Update 'teams' last so other tables can be used as a reference
  $sth = $dbh->prepare("update teams set name='$replacement' WHERE owner='$real_owner' and league='$real_league'");
  $sth->execute();
  $sth->finish();

  $return_line.="team=$real_league,$replacement;";
}

## Make any changes to "owner" last, as all others reference this value
if (defined($in_vars{'owner'}))
{
  $replacement = $in_vars{'owner'};
  $sth_check = $dbh->prepare("select count(*) from passwd where name='$replacement'");
  $sth_check->execute();
  $status = $sth_check->fetchrow();
  $sth_check->finish();

  if ($status == 0)
  {
    $sth = $dbh->prepare("update passwd set name='$replacement' WHERE name='$real_owner'");
    $sth->execute();
    $sth->finish();

    $sth = $dbh->prepare("update leagues set owner='$replacement' where owner='$real_owner'");
    $sth->execute();
    $sth->finish();

    $sth = $dbh->prepare("update sessions set owner='$replacement' where owner='$real_owner'");
    $sth->execute();
    $sth->finish();

    $sth = $dbh->prepare("update teams set owner='$replacement' where owner='$real_owner'");
    $sth->execute();
    $sth->finish();

    $sth = $dbh->prepare("update contracts set team='$replacement' where team='$real_owner'");
    $sth->execute();
    $sth->finish();

    $return_line.="owner=$replacement;";
  }
  else
  {
    ## Report some Error?
  }
}

chop($return_line);
dbDisconnect($dbh);

print "Content-type: text/html\n\n";
print "$return_line";
