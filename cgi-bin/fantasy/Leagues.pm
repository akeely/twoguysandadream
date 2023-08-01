package Leagues;

use CGI::Carp qw(fatalsToBrowser);
use strict;
use DBI;

sub new {
  my $class = shift;
  my $self = {};

  my $leagueid = shift;
  $self->{_DB_HANDLE} = shift;

  if (! defined $self->{_DB_HANDLE}){
    return undef;
  }
  if (! defined $leagueid){
    return undef;
  }

  ## Fetch all data for this league
  my $leagueH = $self->{_DB_HANDLE}->prepare("select name,password,ownerid,draft_type,draft_status,keepers_locked,sport,max_teams,salary_cap,auction_length,bid_time_ext,bid_time_buff,tz_offset,login_ext,sessions_flag,keeper_increase, previous_league
                        from leagues where id=$leagueid") or die $self->{_DB_HANDLE}->errstr;
  $leagueH->execute();
  my @vals = $leagueH->fetchrow_array();

  ## Assign all single-value items
  $self->{_NAME}            = $vals[0];
  $self->{_PASSWORD}        = $vals[1];
  $self->{_OWNER}           = $vals[2];
  $self->{_DRAFT_TYPE}      = $vals[3];
  $self->{_DRAFT_STATUS}    = $vals[4];
  $self->{_KEEPERS_LOCKED}  = $vals[5];
  $self->{_SPORT}           = $vals[6];
  $self->{_MAX_TEAMS}       = $vals[7];
  $self->{_SALARY_CAP}      = $vals[8];
  $self->{_AUCTION_LENGTH}  = $vals[9];
  $self->{_BID_TIME_EXT}    = $vals[10];
  $self->{_BID_TIME_BUFF}   = $vals[11];
  $self->{_TZ_OFFSET}       = $vals[12];
  $self->{_LOGIN_EXT}       = $vals[13];
  $self->{_SESSIONS_FLAG}   = $vals[14];
  $self->{_KEEPER_INCREASE} = $vals[15];
  $self->{_PREV_LEAGUE}     = $vals[16];


  ## Get multi-value items
  my $catsH = $self->{_DB_HANDLE}->prepare("select category from categories where leagueid=$leagueid");
  $catsH->execute();
  while (my $cat = $catsH->fetchrow())
  {
    $self->{_CATEGORIES}->{$cat} = 1;
  }
  $catsH->finish();

  my $positionsH = $self->{_DB_HANDLE}->prepare("select position from positions where leagueid=$leagueid");
  $positionsH->execute();
  while (my $pos = $positionsH->fetchrow())
  {
    $self->{_POSITIONS}->{$pos} = 1;
  }
  $positionsH->finish();

  my $fa_priceH = $self->{_DB_HANDLE}->prepare("select position, price from fa_keepers where leagueid=$leagueid");
  $fa_priceH->execute();
  while (my ($pos,$price) = $fa_priceH->fetchrow())
  {
    $self->{_FA_KEEPER_PRICES}->{$pos} = $price;
  }
  $fa_priceH->finish();

  my $contractsH = $self->{_DB_HANDLE}->prepare("select min, max, number from keeper_slots where leagueid=$leagueid");
  $contractsH->execute();
  while (my ($min,$max,$num) = $contractsH->fetchrow_array())
  {
    $self->{_KEEPER_SLOTS}->{"$min|$max"} = $num;
  }
  $contractsH->finish();

  bless ($self, $class);
  return $self;
}

sub name {
    my $self = shift;
    if (@_) { $self->{_NAME} = shift }

    return "" unless (defined $self->{_NAME});
    return $self->{_NAME};
}

sub password {
    my $self = shift;
    if (@_) { $self->{_PASSWORD} = shift }

    return "" unless (defined $self->{_PASSWORD});
    return $self->{_PASSWORD};
}

sub owner {
    my $self = shift;
    if (@_) { $self->{_OWNER} = shift }

    return "" unless (defined $self->{_OWNER});
    return $self->{_OWNER};
}

sub draft_type {
    my $self = shift;
    if (@_) { $self->{_DRAFT_TYPE} = shift }

    return "" unless (defined $self->{_DRAFT_TYPE});
    return $self->{_DRAFT_TYPE};
}

sub draft_status {
    my $self = shift;
    if (@_) { $self->{_DRAFT_STATUS} = shift }

    return "" unless (defined $self->{_DRAFT_STATUS});
    return $self->{_DRAFT_STATUS};
}

sub keepers_locked {
    my $self = shift;
    if (@_) { $self->{_KEEPERS_LOCKED} = shift }

    return "" unless (defined $self->{_KEEPERS_LOCKED});
    return $self->{_KEEPERS_LOCKED};
}

sub sport {
    my $self = shift;
    if (@_) { $self->{_SPORT} = shift }

    return "" unless (defined $self->{_SPORT});
    return $self->{_SPORT};
}

sub max_teams {
    my $self = shift;
    if (@_) { $self->{_MAX_TEAMS} = shift }

    return "" unless (defined $self->{_MAX_TEAMS});
    return $self->{_MAX_TEAMS};
}

sub salary_cap {
    my $self = shift;
    if (@_) { $self->{_SALARY_CAP} = shift }

    return "" unless (defined $self->{_SALARY_CAP});
    return $self->{_SALARY_CAP};
}

sub auction_length {
    my $self = shift;
    if (@_) { $self->{_AUCTION_LENGTH} = shift }

    return "" unless (defined $self->{_AUCTION_LENGTH});
    return $self->{_AUCTION_LENGTH};
}

sub bid_time_ext {
    my $self = shift;
    if (@_) { $self->{_BID_TIME_EXT} = shift }

    return "" unless (defined $self->{_BID_TIME_EXT});
    return $self->{_BID_TIME_EXT};
}

sub bid_time_buff {
    my $self = shift;
    if (@_) { $self->{_BID_TIME_BUFF} = shift }

    return "" unless (defined $self->{_BID_TIME_BUFF});
    return $self->{_BID_TIME_BUFF};
}

sub tz_offset {
    my $self = shift;
    if (@_) { $self->{_TZ_OFFSET} = shift }

    return "" unless (defined $self->{_TZ_OFFSET});
    return $self->{_TZ_OFFSET};
}

sub login_ext {
    my $self = shift;
    if (@_) { $self->{_LOGIN_EXT} = shift }

    return "" unless (defined $self->{_LOGIN_EXT});
    return $self->{_LOGIN_EXT};
}

sub sessions_flag {
    my $self = shift;
    if (@_) { $self->{_SESSIONS_FLAG} = shift }

    return "" unless (defined $self->{_SESSIONS_FLAG});
    return $self->{_SESSIONS_FLAG};
}

sub keeper_increase {
    my $self = shift;
    if (@_) { $self->{_KEEPER_INCREASE} = shift }

    return "" unless (defined $self->{_KEEPER_INCREASE});
    return $self->{_KEEPER_INCREASE};
}

sub categories {
    my $self = shift;

    return ( join('|', keys %{$self->{_CATEGORIES}}));
}

sub positions {
    my $self = shift;

    return ( join('|', keys %{$self->{_POSITIONS}}));
}

sub keeper_fa_price {
    my $self = shift;
    my $pos = shift;
    
    if (defined $self->{_FA_KEEPER_PRICES}->{$pos})
    {
      return ($self->{_FA_KEEPER_PRICES}->{$pos});
    }

    ## Return -2 if no fa price assigned for this position
    return (-2);
}

sub keeper_slots {
    my $self = shift;
    my $returns = '';

    ## return "min1|max1|count1,min2|max2|count2, ..."
    foreach my $key ( sort by_max keys %{$self->{_KEEPER_SLOTS}} )
    {
      $returns .= "$key|" . $self->{_KEEPER_SLOTS}->{$key} . ',';
    }
    chop($returns);

    $returns;
}

sub prev_league {
    my $self = shift;
    if (@_) { $self->{_PREV_LEAGUE} = shift }

    return "" unless (defined $self->{_PREV_LEAGUE});
    return $self->{_PREV_LEAGUE};
}

sub by_max {
  my ($min1,$max1) = split(/\|/,$a);
  my ($min2,$max2) = split(/\|/,$b);

  $max2 <=> $max1; 
}


1;
