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

my $tt = TestTools->new;

my $mech = Test::WWW::Mechanize::Catalyst->new;

#login
our $account1 = { email => 'foo@api.com',
              password => 'Test@123',
              first_name => 'Foo',
              last_name => 'Bar',
};


#Create tests

#deleting all accounts
$tt->delete_all_accounts();

#create default roles
$tt->create_default_roles();

#create account - all data ok! 
$mech->post('/account', $account1);
my $json = decode_json($mech->content);
my $account_id;

ok($json->{status_code} eq '200','create innactive account');
$account_id = $json->{account}->{id};
my $model = API->model('APIDB::ActivationKey');
  
#resend key - no params
$mech->post('/account/send-activation-key',);
ok(!$mech->success,'send-activation-key no params');
  
  $mech->post('/account/send-activation-key',{foo => 'bar'});
  ok(!$mech->success,'send-activation-key invalid params');

  #resend key - params allright
  $mech->post('/account/send-activation-key',{account_id => $account_id,});
  if($mech->success){
    #getting the last key
    my ($key) = $model->search({ account_id => $account_id,
                             expired_at => { '>' => \'now()'},
                        });
   
    ok(defined($key),'found activation key');
    my $new_activation_key = $key->activation_key;
    #activating user - all parameters ok!
    $mech->post('/account/activate',{ account_id => $account_id, 
                                    activation_key => $new_activation_key,
                                    } );
    say STDERR "ACTIVATION AFTER NEW KEY: " . $mech->content;
    ok($mech->success,'Activation account succeeded!');
    if($mech->success){
      $model = API->model('APIDB::Account');
      my ($account_data) = $model->search({ id => $account_id });
      ok($account_data->active,'Account activation really active');
      undef $account_data;
    }
    else { die }
  }
  else { die }

#create same account
$mech->post('/account', $account1);
my $json = decode_json($mech->content);
ok($json->{status_code} eq '400','create same account');

#delete all again
$tt->delete_all_accounts();

#create account, missing data
foreach my $target('email', 'password', 'first_name', 'last_name'){
  my $data = { email => 'foo@api.com',
              password => 'Test@123',
              first_name => 'Foo',
              last_name => 'Bar',
            };
  $data->{$target} = undef;
  $mech->post('/account',$data);
  my $json = decode_json($mech->content);
  ok($json->{status_code} eq '400',qq/create account without $target/);
}

#create account, invalid data
foreach my $target('email', 'password', 'first_name', 'last_name'){
  my $data = { email => 'foo@api.com',
              password => 'Test@123',
              first_name => 'Foo',
              last_name => 'Bar',
            };
  $data->{$target} = 'invalid value';
  $mech->post('/account',$data);
  my $json = decode_json($mech->content);
  ok($json->{status_code} eq '400',qq/create account with invalid $target/);
}




#delete all again
$tt->delete_all_accounts();


done_testing();























