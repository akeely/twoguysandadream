package YahooAPIoauth;

use lib qw(/capfs/print_advs/lib);

use strict;
use DBI;
use URI;
use URI::Escape;
##use XML::Simple;
use LWP::Simple;

use MyOAuthApp;

my $default_results_desired = 20;

## Old v1 Boss stuff
##my $base_url = 'http://boss.yahooapis.com/ysearch/web/v1/';
##my $appid = 'UujlBELV34H5y24N3posu9CLNZlUvcp75CYN7Pf10Rjx4HJNa.ncAwNc.vFoCFM-';

my $base_url = 'http://yboss.yahooapis.com/ysearch/limitedweb';

## Connect to Yahoo Oauth API
my $oauth = Net::MyOAuthApp->new();
$oauth->ConnectToYahoo();

## List of yellowpages-ish sources that we will to BLACKLIST
##  ie - do not consider these for assignment as primary URL
my %all_counts;
my %blacklist_counts;

## These blacklist URLs need wildcards (ie, boston.citysearch.com versus worcester.citysearch.com)
my %blacklist_wildcards = (
                            '*.yahoo.com'      => 1,
                            'directory.*.com'  => 1,
                            '*.wikipedia.org'  => 1,
                            '*.directorym.net' => 1,
                            '*.citysearch.com' => 1,
                            '*yellowpages*'    => 1
                          );
                            
## These blacklist URLs are explicity authorities - no need for wildcards
my %blacklist_urls = (
                       'business-directory-usa.com' => 1,
                       'gomylocal.com' => 1,
                       'thefreelibrary.com' => 1,
                       'waymarking.com' => 1,
                       'local.yodle.com' => 1,
                       'downtownme.com' => 1,
                       'findasalon.net' => 1,
                       'serviceslisted.com' => 1,
                       'ibegin.com' => 1,
                       'americantowns.com' => 1,
                       'zvents.com' => 1,
                       'givereal.com' => 1,
                       'thomasnet.com' => 1,
                       'decidio.com' => 1,
                       'jobsearch.monster.com' => 1,
                       'looboo.com' => 1,
                       'theusaexplorer.com' => 1,
                       'whitepages.com' => 1,
                       'bbb.org' => 1,
                       'pennysaverusa.com' => 1,
                       'snapspans.com' => 1,
                       'local.botw.org' => 1,
                       'allbusiness.com' => 1,
                       'findabeautysalon.com' => 1,
                       'hoovers.com' => 1,
                       'nethulk.com' => 1,
                       'localbusinessexplorer.com' => 1,
                       'talkingphonebook.com' => 1,
                       'careerbuilder.com' => 1,
                       'iaf.net' => 1,
                       'sites.google.com' => 1,
                       'menuism.com' => 1,
                       'backfence.com' => 1,
                       'edmunds.com' => 1,
                       'b2byellowpages.com' => 1,
                       'sbn.com' => 1,
                       'find.mapmuse.com' => 1,
                       'kellysearch.com' => 1,
                       'go2.com' => 1,
                       'epodunk.com' => 1,
                       'menupix.com' => 1,
                       'checkbook.org' => 1,
                       'zipperpages.com' => 1,
                       'city-data.com' => 1,
                       'manufacturersnews.com' => 1,
                       'findcontractor.org' => 1,
                       'urbanspoon.com' => 1,
                       'centerd.com' => 1,
                       'marketplace.mediaonene.com' => 1,
                       'findhairstyles.com' => 1,
                       'ebizdir.net' => 1,
                       'yellowpages.aol.com' => 1,
                       'localism.com' => 1,
                       'bizvotes.com' => 1,
                       'boorah.com' => 1,
                       'discoverourtown.com' => 1,
                       'cylex-usa.com' => 1,
                       'nexport.com' => 1,
                       'outside.in' => 1,
                       'realtor.com' => 1,
                       'takeouttonight.com' => 1,
                       'justclicklocal.com' => 1,
                       'brownbook.net' => 1,
                       'wickedlocal.com' => 1,
                       'mojopages.com' => 1,
                       'servicemagic.com' => 1,
                       'pagelink.com' => 1,
                       'industrynet.com' => 1,
                       'looklocally.com' => 1,
                       'insiderpages.com'         => 1,
                       'google.com'               => 1,
                       'yellowpages.com'          => 1,
                       'yellowpages.superpages.com'           => 1,
                       'superpages.com'           => 1,
                       'switchboard.com'          => 1,
                       'localsearch.com'          => 1,
                       'mapquest.com'             => 1,
                       'citysquares.com'          => 1,
                       'yelp.com'                 => 1,
                       'kudzu.com'                => 1,
                       'antiqueshoppingguide.com' => 1,
                       'uptake.com'               => 1,
                       'hotels.com'               => 1,
                       'tripadvisor.com'          => 1,
                       'yellowpagecity.com'       => 1,
                       'travels.com'              => 1,
                       'flickr.com'               => 1,
                       'local.com'                => 1,
                       'wellness.com'             => 1,
                       'dexknows.com'             => 1,
                       'magicyellow.com'          => 1,
                       'manta.com'                => 1,
                       'yellowbook.com'           => 1,
                       'merchantcircle.com'       => 1,
                     );

sub new
{
  my $class = shift;
  my $results_desired = shift || $default_results_desired;
  my $verbose = shift || 0;
  my $self = {};
  bless($self,$class);

  # global copy of the XML parser which gets reused for each XML API invocation
##  $self->{PARSER} = new XML::Simple;

  $self->{RESULTS} = $results_desired;
  $self->{VERBOSE} = $verbose;
  $self->{RESULTNUM} = 0;

  return($self);
}

sub search_listing
{
  my $self = shift;
  my $query = shift;
  my %qhash = @_;

  ## Old Boss stuff
  ##my $url = $base_url . $query . "?appid=$appid&format=xml&count=" . $self->{RESULTS};

  $query = uri_escape($query);
  my $url = $base_url;
  ##my $url = $base_url . "?q=$query";
  ##my $url = 'http://yboss.yahooapis.com/ysearch/web?q=yahoo&format=xml';
  print "URL: $url\n" if ($self->{VERBOSE});

  $self->{RESULTNUM} = 0;
  delete $self->{CONTENT};
  delete $self->{XMLDATA};
  $self->{URLS} = ();
  eval {
      local $SIG{ALRM} = sub { die "alarm\n" };
      alarm(15); # timeout after 15 seconds
      $self->{RESPONSE} = $oauth->view_restricted_resource("$url",%qhash);
      $self->{CONTENT}=$self->{RESPONSE}->{_content};
      alarm(0);

    while ($self->{CONTENT} =~ /<url>(.*)<\/url>/g)
    {
      push(@{$self->{URLS}},$1);
    }
##print "CONTENT: $self->{CONTENT}\n";

  };
  if ($@) {
      print "Timed out on call to $url ($@)\n\n";
      return;
  }
}

sub get_result_url
{
  my $self = shift;
  
  my $yahoo_url = 'NULL';
  while (1)
  {
    ## Check if we have exhausted all results
    if ((! defined $self->{URLS}) || (@{$self->{URLS}} == 0))
    {
      print "Parsed all available results!\n" if ($self->{VERBOSE});
      $yahoo_url = 'NULL';
      last;
    }

    $yahoo_url = shift(@{$self->{URLS}});
    $self->{RESULTNUM}++;

    ## Check for blacklisted domains
    my $uri = URI->new($yahoo_url);
    my $authority = $uri->authority;
    $authority =~ s/^www\.//;

    ###
    ## Blacklist URL checks
    ###
    print "Checking authority '$authority'\n" if ($self->{VERBOSE});
    my $is_blacklist = 0;
    if (defined $blacklist_urls{$authority})
    {
      print "Skipping Blacklisted authority '$authority' in URL '$yahoo_url'\n" if ($self->{VERBOSE});
      $blacklist_counts{$authority}++;
      next;
    }
    ## BL WildCard checks
    foreach my $black_wc (keys %blacklist_wildcards)
    {
      if ($authority =~ /^$black_wc$/)
      {
        print "Skipping Blacklist (wc) authority '$authority' in URL '$yahoo_url'\n" if ($self->{VERBOSE});
        $blacklist_counts{$black_wc}++;
        $is_blacklist = 1;
        last;
      }
    }

    ## If we caught any wildcard blacklist violations - skip this URL entry
    next if ($is_blacklist);

    ###
    ## Not blacklisted - return it for the calling process
    ###

    $all_counts{$authority}++;
    print "FOUND '$yahoo_url'\n" if ($self->{VERBOSE});
    last;
  }
  
  return $yahoo_url;
}

sub display_stats
{
  my $self = shift;
  my $report_threshold = shift || 20;

  print "Blacklisted URL instances:\n";
  foreach my $burl (keys %blacklist_counts)
  {
    print "\t$burl : $blacklist_counts{$burl}\n";
  }

  print "Accepted URLs with more than $report_threshold hits:\n";
  foreach my $url (keys %all_counts)
  {
    print "\t$url : $all_counts{$url}\n" if ($all_counts{$url} >= $report_threshold);
  }
}

1;
