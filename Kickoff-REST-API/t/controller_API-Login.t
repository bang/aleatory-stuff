use strict;
use warnings;
use feature qw/say/;
use Test::More ;
use Catalyst::Test 'API';
use API::Controller::API::Resource;
use JSON;
use ok "Test::WWW::Mechanize::Catalyst" => "API";
use Data::Printer colored => 1;

my (@Errors,$decoded);
my $mech = Test::WWW::Mechanize::Catalyst->new;

#Login without parameters
my $r = $mech->post('/login');
ok(($mech->status == 400), 'Login without parameters');


#Login with empty parameters
$mech->post('/login', { email => '',
                                             password => '',
          });

$decoded = decode_json( $mech->content );
@Errors = @{$decoded->{error}};

ok( ($mech->status == 400 and scalar(@Errors))  , 'Login with empty parameters');




#Login with undef parameters(must have same behavior that empty parameters
$mech->post('/login', { email  => undef,
                                             password => undef,
          });

$decoded = decode_json( $mech->content );
@Errors = @{$decoded->{error}};

ok(($mech->status == 400 and scalar(@Errors)) , 'Login with undef parameters');


#Login with invalid e-mail and missing password
$mech->post('/login', { email  => 'not a valid email format',
                                             password => undef,
          });

$decoded = decode_json( $mech->content );
@Errors = @{$decoded->{error}};
say STDERR p @Errors;
say STDERR $mech->status;
ok(($mech->status == 400 and scalar(@Errors) == 2 ) , 'Invalid e-mail and missing password');

#Check recieve access_key after successful log-in
#create a test user

$mech->post('/login', { email  => 'test@api.com',
                                   password => 'Test@123',
          });

my $json = decode_json($mech->content);
my $access_key = $json->{'access-key'};
say STDERR "ACCESS_KEY: $access_key";
ok( defined($access_key) and $access_key  , 'access key ok!');



done_testing();























