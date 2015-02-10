package Net::MyOAuthApp;

use strict;
use base qw(Net::OAuth::Simple);

## Constants
my $appid='6VDRiN5a';
my $key = 'dj0yJmk9TXA5YU1laUsyRENqJmQ9WVdrOU5sWkVVbWxPTldFbWNHbzlNVGMxT1RRNU5UYzJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD03Zg--';
my $secret = '11b1e8b55d42990e59558957b20dd89b5b9e019b';

##my $key = 'dj0yJmk9UFJsNXpyZFJtcFRLJmQ9WVdrOVR6aFNRbGhsTTJNbWNHbzlNamN6T0RJeU5UWXkmcz1jb25zdW1lcnNlY3JldCZ4PTM1';
##my $secret = 'b4788dd8f9017a614afd60fd754c7ea054a71290';

my %default_tokens;
$default_tokens{consumer_key} = $key;
$default_tokens{consumer_secret} = $secret;

sub new {
    my $class  = shift;
    my %tokens = @_ || %default_tokens;
    return $class->SUPER::new( tokens => \%tokens, 
                               protocol_version => '1.0a',
                               urls   => {
                                    authorization_url => 'https://api.login.yahoo.com/oauth/v2/request_auth',
                                    request_token_url => 'https://api.login.yahoo.com/oauth/v2/get_request_token',
                                    access_token_url  => 'https://api.login.yahoo.com/oauth/v2/get_token'
                               });
}

sub view_restricted_resource {
    my $self = shift;
    my $url  = shift;
    my %extras = @_;

    return $self->make_restricted_request($url, 'GET', %extras);
}

sub update_restricted_resource {
    my $self         = shift;
    my $url          = shift;
    my %extra_params = @_;
    return $self->make_restricted_request($url, 'POST', %extra_params);    
}
1;

sub ConnectToYahoo {
  my $self = shift;

  # Check to see we have a consumer key and secret
  unless ($self->consumer_key && $self->consumer_secret) {
    die "You must go get a consumer key and secret from App\n";
  }

  $self->signature_method('PLAINTEXT');

  my $authurl = $self->get_authorization_url(callback => "oob");##http://www.twoguysandadream.com/cgi-bin/fantasy/getTeam.pl");
  print "Go to '$authurl'\n";
  print "Then enter the verification code and hit return after\n";
  my $verifier = <STDIN>;


  ## After we get the verifier code from the user, fetch the access token (stored internally)
  my %test = (verifier => $verifier);
  my ($access_token, $access_token_secret) = $self->request_access_token(%test);

  ## Reset signature method for restricted requests
  $self->signature_method('HMAC-SHA1');
}
