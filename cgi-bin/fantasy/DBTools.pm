package DBTools;
use strict;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

require Exporter;
our @ISA = qw(Exporter);
use vars qw/@EXPORT/;
@EXPORT = qw/dbConnect dbDisconnect setCmdLine/;

my $dburl = "DBI:mysql:auction:akeely-auction.cwp74fsixexb.us-east-1.rds.amazonaws.com";
my $dbuser = "akeely";
my $dbpass = '6CV#GVloZ%TVF$Rg';

sub setCmdLine($)
{
  my $is_cmd = shift;
  $dburl = "DBI:mysql:database=akeely_auction:host=localhost" if (defined $is_cmd);
}

sub dbConnect() {
    my $dbh = DBI->connect($dburl,$dbuser,$dbpass) 
              or die "Couldn't connect to database: " .  DBI->errstr;
}

sub dbDisconnect($) {
    my $dbh = shift;
    $dbh->disconnect();
}

1;
