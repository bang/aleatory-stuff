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
  ok($json->{status_code} eq '200','create innactive account');
  $account_id = $json->{account}->{id};

  #reading account without authentication key
  $mech->get('/account/id',{id => $account_id});
  say STDERR $mech->content;
  my $json = decode_json($mech->content);
  ok($json->{status_code} == 401 , 'read account without login');
 
  #log-in
  my $access_key = $tt->login($account1);

  #reading innactive account with authentication key
  $mech->add_header('Authentication' => 'UUID ' . $access_key);
  $mech->get('/account/id',{id => $account_id});
  $json = decode_json($mech->content);
  ok($json->{status_code} == 401, 'trying read innactive account');

  #force activate account(via DB)
  $tt->force_activate_account($account_id);
  
  #now, that's ok!
  $mech->get( qq(/account/id?id=$account_id) );
  $json = decode_json($mech->content);
  ok($json->{status_code} == 200,'reading active account');

  #gettin with invalid account_id
  my $old = $account_id;
  $account_id = 'invalid value';
  $mech->get( qq(/account/id?id=$account_id) );
  $json = decode_json($mech->content);
  ok($json->{status_code} == 400,'get account data with invalid account id');

  #creating another account
  $tt->create_account('Zaz','Traz');
  my $account2 = { first_name => 'Zaz',
                   last_name => 'Traz',
                   email => 'zaz_traz@foobar.com',
                   password => 'Foobar@123',
                };

  #trying to read account another account info 
  $mech->get( q(/account/email?email=zaz_traz@foobar.com) );
  ok($mech->status() == 401, 'read another account without permission'); 

  #trying to read all accounts without permission to do that  
  $mech->get( q(/account/all) );
  ok($mech->status() == 401, 'read all accounts without superuser permission'); 

  #TODO read suspended account


}
else { die;}


$tt->delete_all_accounts();

done_testing();







