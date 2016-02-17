use strict;
use warnings;
use feature qw/say/;
use Test::More;
use Catalyst::Test 'API';
use API::Controller::API::Group;
use ok "Test::WWW::Mechanize::Catalyst" => "API";
use Data::Printer colored => 1;
use JSON;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

my (@Errors,$decoded);
ok(my $mech = Test::WWW::Mechanize::Catalyst->new, 'Agent instance');

my $address = 'http://localhost:3000/group';
$mech->post($address);
$decoded = decode_json($mech->content);
ok($decoded->{status_code} eq '401','Try to create without authorization');




done_testing();

