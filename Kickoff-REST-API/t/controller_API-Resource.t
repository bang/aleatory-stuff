use strict;
use warnings;
use Test::More;


use Catalyst::Test 'API';
use API::Controller::API::Resource;
use JSON;
use ok "Test::WWW::Mechanize::Catalyst" => "API";

use feature qw/say/;
use Data::Printer colored => 1;

#Testing upload
#curl --form "path=@/home/eokoe/crap" http://localhost:3000/resource/upload

my $Users = { u1 => { email => 'andregarciacarneiro@gmail.com',
                      password => 'Andre@123'
                    },
            };

my $ua1 = Test::WWW::Mechanize::Catalyst->new;

my $res = request('/resource/all');
my $decoded = decode_json($res->content);
ok( $decoded->{status_code} == 401, 'All resources without authentication' );


#login
$ua1->post_ok('/login',$Users->{u1},'Correct login');
$res = $ua1->res;
$decoded = decode_json($res->content);
my $access_key = $decoded->{'access-key'};
ok(defined($access_key) and $access_key, 'access key ok!');

#requesting all resources with the access-key
$ua1->{headers} = {Authentication => 'UUID ' . $access_key};

$ua1->get_ok('/resource/all');
$res = $ua1->res;
$decoded = decode_json($res->content);
#ok( $decoded->{status_code} == 200 and ref($decoded->{resources} eq 'ARRAY'), 'all resources ok' );

#$access_key = 'invalid-key';
#$ua1->{headers} = {Authentication => 'UUID ' . $access_key};
#$ua1->get_ok('/resource/all',);
#$decoded = decode_json($res->content);
#say STDERR p $decoded->{status_code};
#ok( $decoded->{status_code} == 401, 'invalid access-key' );

done_testing();
