use strict;
use warnings;
use feature qw/say/;
use Data::Printer colored => 1;
use Test::More;
use Catalyst::Test 'API';
use API::Controller::API::Account;
use ok "Test::WWW::Mechanize::Catalyst" => "API";
use JSON;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use TestTools;


my $mech = Test::WWW::Mechanize::Catalyst->new;

#login
our $account1 = { email => 'foo@api.com',
              password => 'Test@123',
              first_name => 'Foo',
              last_name => 'Bar',
};

my $tt = TestTools->new;

#deleting all accounts
$tt->delete_all_accounts();

#create default roles
$tt->create_default_roles();

#create account - all data ok!
$mech->post('/account', $account1);
my $account_id;
if($mech->success){
  my $json = decode_json($mech->content);
  $account_id = $json->{account}->{id};
  #reset password, innactive account
  $mech->post('/account/reset-password',$account1);
  $json = decode_json($mech->content);
  ok($json->{status_code} eq '401','reset password with innactive account');

  #forcing activate account(via DB)
  $tt->force_activate_account($account_id);
  
  #Try again with active account
  $mech->post('/account/reset-password',$account1);
  say STDERR $mech->content;
  $json = decode_json($mech->content);
  ok($json->{status_code} eq '200','reset password with active account');

  #forcing suspend account(via DB)
  $tt->suspend_account($account_id);

  #Try again with active account
  $mech->post('/account/reset-password',$account1);
  $json = decode_json($mech->content);
  ok($json->{status_code} eq '401','reset password with suspended account');

  #Try again with undef parameters
  $mech->post('/account/reset-password',);
  $json = decode_json($mech->content);
  ok($json->{status_code} eq '400','reset password with undef parameters');

  #Try again with invalid email
  $mech->post('/account/reset-password',{email => 'this is not a valid email'});
  $json = decode_json($mech->content);
  ok($json->{status_code} eq '400','reset password with invalid email');
 
}
else { die; }

$tt->delete_all_accounts();

done_testing();


