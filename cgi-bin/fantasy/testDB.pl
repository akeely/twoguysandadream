#!/usr/bin/perl -w

use strict;
use DBTools;

my $dbh = dbConnect();

my $sth_names = $dbh->prepare("SELECT name FROM passwd");
$sth_names->execute();
while (my $owner = $sth_names->fetchrow()) {
    print "Owner: $owner\n";
}

$sth_names->finish();

dbDisconnect($dbh);
