use strict;
use warnings;
use feature qw/say/;

package TestTools;
use Moose;
use URI;
use Data::Printer colored => 1;
use Test::More;

use Catalyst::Test 'API';
use API::Controller::API::Account;
use ok "Test::WWW::Mechanize::Catalyst" => "API";
use JSON;

has mech => (
    is => 'rw',
    default => sub {
      return Test::WWW::Mechanize::Catalyst->new;
    },
);


sub crap {
  say STDERR 'this is crap!';
}

sub create_test_account {
  my ($self,$index) = @_;
  $index = 1 if !defined($index);
  
}

sub login {
  my ($self,$data) = @_;
  my $r = $self->mech->post('/login', $data);
  my $json = decode_json($self->mech->content);
  my $access_key = $json->{'access-key'};
  undef $json;
  return $access_key;
}

sub delete_all_accounts {
  my $prefix = 'APIDB::';
  map{ API->model($prefix . $_)->search()->delete } qw/ActivationKey PasswordKey AccessKey AccountRole Role Account/;
}

sub force_activate_account {
  my ($self,$account_id) = @_;
  die qq/Can't activate account because parameter account_id is invalid!(account_id: $account_id)/
    if !defined($account_id) or $account_id !~ /^\d+$/;

  my $model = API->model('APIDB::Account');
  eval{$model->search({ id => $account_id })->update({ active => 1 });};
  die $@ if $@;
}

sub suspend_account {
  my ($self,$account_id) = @_;
  die qq/Can't suspend account because parameter account_id is invalid!(account_id: $account_id)/
    if !defined($account_id) or $account_id !~ /^\d+$/;

  my $model = API->model('APIDB::Account');
  eval{$model->search({ id => $account_id })->update({ suspended_at => 'now()' });};
  die $@ if $@;
}

sub create_default_roles {
  my ($self) = @_;
  my $model = API->model('APIDB::Role');
  eval{ $model->create({ id => 1, role => 'superuser' }); 
        $model->create({ id => 2, role => 'members' });
  };
  die if $@ and $@ !~ /duplica/;
    
}

sub create_account {
  my ($self,$first_name, $last_name) = @_;
  die if !defined($first_name) or !$first_name;
  die if !defined($last_name) or !$last_name;
  my $model = API->model('APIDB::Account');
  my $email = lc( join('_',$first_name,$last_name) ) . '@' . 'foobar.com';
  $self->mech->post('/account',{email => $email,
                                password => 'Foobar@123',
                                first_name => $first_name,
                                last_name => $last_name,
                                });
  die $self->mech->content if !$self->mech->success;
  return 1;
}




sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  $string =~ s/(\s\s|\s\s\s)+/ /g;
  return $string;
}


























1;
