package Net::MyOAuthApp;

use strict;
use LWP::Authen::OAuth2;

## Constants
my $appid='6VDRiN5a';
#my $key = 'dj0yJmk9TXA5YU1laUsyRENqJmQ9WVdrOU5sWkVVbWxPTldFbWNHbzlNVGMxT1RRNU5UYzJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD03Zg--';
#my $secret = '11b1e8b55d42990e59558957b20dd89b5b9e019b';

my $key = 'dj0yJmk9YUNNN05GZWdBcFZRJmQ9WVdrOWNXWmFObUZaTm0wbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD01Nw--';
my $secret = '17411159ce179ed5d286f2a16158d4da4285325b';
sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless($self, $class);
    $self->{client} = LWP::Authen::OAuth2->new( client_id => $key,
                     client_secret =>  $secret,
                     authorization_endpoint => 'https://api.login.yahoo.com/oauth2/request_auth',
                     token_endpoint => 'https://api.login.yahoo.com/oauth2/get_token',
                     redirect_uri => "oob");
#    return $class->SUPER::new( tokens => \%tokens, 
#                               protocol_version => '1.0a',
#                               urls   => {
#                                    authorization_url => 'https://api.login.yahoo.com/oauth/v2/request_auth',
#                                    request_token_url => 'https://api.login.yahoo.com/oauth/v2/get_request_token',
#                                    access_token_url  => 'https://api.login.yahoo.com/oauth/v2/get_token'
#                               });
#
    return $self;
}

sub view_restricted_resource {
    my $self = shift;
    my $url  = shift;

    return $self->{client}->get($url);
}

sub update_restricted_resource {
    my $self         = shift;
    my $url          = shift;
    my %extra_params = @_;
    return $self->{client}->request($url, 'POST', %extra_params);    
}

sub ConnectToYahoo {
  my $self = shift;

#  $client->signature_method('PLAINTEXT');

  my $authurl = $self->{client}->authorization_url(redirect_uri => "oob");
  print "Go to '$authurl'\n";
  print "Then enter the verification code and hit return after\n";
  my $verifier = <STDIN>;


  ## After we get the verifier code from the user, fetch the access token (stored internally)
  my %test = (
    code => $verifier
  );
  my ($access_token, $access_token_secret) = $self->{client}->request_tokens(%test);

  ## Reset signature method for restricted requests
#  $client->signature_method('HMAC-SHA1');
}
