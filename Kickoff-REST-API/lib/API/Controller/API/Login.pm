package API::Controller::API::Login;
use common::sense;
use Moose;
use namespace::autoclean;
use JSON;
use Data::Dumper;
use Data::Printer colored => 1;
use API;
use UUID::Tiny;
use Digest::SHA;
use feature qw/say/;

BEGIN { extends 'Catalyst::Controller'; }




our $RESOURCE = 'Login';

sub setup :Chained('/') :PathPart('login') :CaptureArgs(0) {
  my ($self,$c) = @_;

}

use Digest::SHA qw/sha1_hex/;

sub login :Chained('setup') :PathPart('') :Args(0) POST {
  my ($self,$c ) = @_;
  my $dt = API::get_local_date();
  my $params = $c->req->params;
  my ($email,$password) = ($params->{email},
                           $params->{password}
                           );

  my $auth;
  if($c->treat_data('Login','login',$params) ){
    eval{
      say "email: $email";
      say "password: $password";
      $auth = $c->authenticate( { email => $email,
                          password => $password,
                         },
                        );
    };
    if($@){
      $c->stash->{error} = [q/Can't login!/];
      $c->stash->{status_code} = 500;
      say "LOGIN ERROR: $@";
    }
    elsif(!$auth){
      $c->stash->{error} = [{Login => q/User or password invalid!/}];
      $c->stash->{status_code} = 401;
    }
    else { 
      use DDP;
      say "CONTEXT: " . p $c;
      say "USER_EXISTS: " . p $c->user_exists;
      say "USER: " . p $c->user if $c->user_exists;
      $c->stash->{'access-key'} = $self->create_access_key($c);
    }
  }
  $c->out;
}

sub expire_user_keys {
  my ($self,$c) = @_;
  my $ok = 0;
  my $model = $c->model('APIDB::AccessKey');
  my $r;
  eval{
    ($r) = $model->search({
            account_id => $c->user->id,
         })->update({
            'duration' => \"tstzrange(LOWER(duration),now(),'[)')",            
         });
  };
  if($@){
    say "EXPIRE KEY ERROR: $@"; 
    $c->stash->{status_code} = 500;
    $c->stash->{error} = [{access_keys => 'There is problems with keys! Please, try again later!'}];
  }
  else { $ok = 1; }
  return $ok;
}


sub create_access_key {
  my ($self,$c) = @_;
  if($self->expire_user_keys($c)){
    my $model = $c->model('APIDB::AccessKey');
    my $r;
    eval{
      ($r) = $model->create({
              account_id => $c->user->id,
           });
    };
    if($@){
      say "LOGIN ERROR: $@"; 
      $c->stash->{status_code} = 500;
      $c->stash->{error} = [access_key => 'Sorry! But was not possible to create your access key now. Please, try later!'];
    }
    else {
      return $r->key;
    }
  }
}


=encoding utf8

=head1 NAME

API::Controller::API::Login - Login endpoints for Opengates API

=head1 DESCRIPTION

CRUD controller for resource entity(table). 

=head1 RESOURCE CRUD ENDPOINTS

=head2 Create resource (POST) - /api/login

Parameters:

=over

=item * Str email: Name of resource;

=item * Str password: Little text content about the resource;

=back



=head1 AUTHOR

André Garcia Carneiro L<andregarciacarneiro@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
