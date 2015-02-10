#!/usr/bin/perl

use strict;
use DBI;
use LWP::Simple;
use URI::Escape;

use lib qw(Net);
use YahooAPIoauth;

$| = 1;
my $results_checked = 10;
my $results_desired = 25;
my $api = new YahooAPIoauth($results_desired,1);

my $advtype = 'reachlocal';
my $target_text = 'reachcast';


my @candidates;
open(IN,"<Project_Orange_Leads--Passaic_1000.csv");
@candidates = <IN>;
close(IN);

open(OUT,">RL_results.phone.out");

my %custids;
my $match_count = 0;
my $count=0;
my $commit_threshold = 5000;
foreach my $check_biz (@candidates)
{
  my @bizinfo = split(/,/,$check_biz);
##@bizinfo = (1,'b','8772298639','d','e','Windsor','g','h','i','j','k','l','m','Englewood','CO','p','q');

  my $custid = $bizinfo[0];
  my $name = $bizinfo[5];
  my $city = $bizinfo[13];
  my $state = $bizinfo[14];
  my $phone1 = $bizinfo[2];
  my $phone2 = $bizinfo[3];
  $name =~ s/["']//g;
  
  next if ($custid =~ /\D/);
  if (defined $custids{$custid})
  {
    print "Duplicate custid '$custid'\n\n";
    next;
  }
  $custids{$custid} = 1;
  
  ## Seach query terms
  my $phone_break = substr($phone1,0,3) .' '. substr($phone1,3,3) .' '. substr($phone1,6,4);
  my %qhash; 
##  $qhash{q} = "$advtype $name $city $state";
  $qhash{q} = "\"$advtype\" $phone_break";
##$qhash{q} = "Yahoo";
  $qhash{format} = 'xml';
  #uri_escape($qhash{q});
  my $query = "$advtype, $name, $city, $state";
print OUT "\n\nQuery Parameters: '$qhash{q}'\n";
print "\n\nQuery Parameters: '$qhash{q}'\n";
  $api->search_listing($query,%qhash);

  my $result_count = 0;
  my $result_url;
  while (1)
  {
    $result_url = $api->get_result_url();

    ## 'NULL' means no more URLs to retrieve
    last if ($result_url eq 'NULL');

    ## Skip target-owned site
    next if ($result_url eq "http://www.reachlocal.com/");

print OUT "Found URL '$result_url' for CUSTID '$custid'\n";
##print "Found URL '$result_url' for CUSTID '$custid'\n";

    ## Grab the web content now and see what we have - just looking for the simple signature
    eval {
      local $SIG{ALRM} = sub { die "alarm\n" };
      alarm(15); # timeout after 15 seconds
      my $content = get $result_url;
      alarm(0);


      if ($content =~ /$target_text/i)
      {
        ## Check for phone match
        my $phone_match = 0;
        while ($content =~ /\(?(\d{3})\)?[-\.\s-]*(\d{3})[\.\s-]*(\d{4})/g)
        ##while ($content =~ /\((\d{3})\)\s(\d{3})\-(\d{4})/g)
        {
          my $temp_phone = $1 . $2 . $3;
  
          print OUT "Phone possibility: $temp_phone\n";
          if (($temp_phone eq $phone1) || ($temp_phone eq $phone2))
          {
            print OUT "\tPHONE match!\n";
            $phone_match = 1;
            last;
          }
        }
        
        print OUT "MATCH! ($custid, $name, $city, $state, phone_match: $phone_match, $result_url)\n";
        $match_count++;

        last if ($phone_match);
      }
      if ($content =~ /reachlocal/i)
      {
        print OUT "HALF match?\n";
      }
    };

    $result_count++;
    last if ($result_count == $results_checked);
  }

  $count++;
  if (($count % $commit_threshold) == 0)
  {
    print "COMMIT (count = $count)\n";
  }
  ##last if ($count == 500);
}

## Show Blacklisted URL occurances
##$api->display_stats(300);

print OUT "Total # of $advtype hits ($target_text): $match_count ($count total)\n";

close(OUT);

