use common::sense;

package API::Controller::Root;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Data::Printer colored => 1;
use JSON;
use Data::Validate::UUID qw/is_uuid/;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=encoding utf-8

=head1 NAME

API::Controller::Root - Root Controller for API

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut 

sub base : Chained('/') : PathPart('') : CaptureArgs(0) {
  my ( $self, $c ) = @_;
  if ( !$self->check_key($c) )
  {    #TODO decide if roles are check here or in each controller.
    $c->stash->{status_code} = 401;
    $c->out(1);
  }

}

sub check_key {
  my ( $self, $c ) = @_;
  my $ok         = 0;
  my $model      = $c->model('APIDB::AccessKey');
  my $headers    = $c->req->headers;
say STDERR 'HEADERS: ' . p $headers;  
  my $access_key = $headers->{'authentication'} || '';

  #loading user auth data from access_key 'account_id'
  my $key = $1 if $access_key =~ /UUID\s+(.*)$/;
  $key = '' if !defined($key);
  if ( $key && is_valid($key) ) {
    eval{
      my ($access) = $model->search(
        {
          'key'             => $key,
          'UPPER(duration)' => { '>' => \'now()' },
        }
      );
      if ( !defined($access) ) {
        $c->stash->{error} = 'Unauthorized! Invalid key!';
        $c->stash->{status_code} = 401;
      }
      else {
        my $account_id = $access->account_id;
        my $acc_model  = $c->model('APIDB::Account');

        my ($account) = $acc_model->search( { id => $account_id, } );
        if ( !defined($account) || !$account ) {
          $c->stash->{status_code} = 401;
          $c->stash->{error} =
  'Unauthorized! Your access key is invalid! To get another one, please perform a new log-in';
        }
        elsif ( !$account->active ) {
          $c->stash->{error} =
  'Unauthorized! Your account was found, but is innactive!';
          $c->stash->{status_code} = 401;
        }
        else {
          $ok = 1;
          my $user = $c->find_user( { id => $account->id } );
          $c->set_authenticated($user);
          $c->stash->{error} = undef;
        }
      }
    };
    if($@){
      $c->stash->{status_code} = 500;
      $c->stash->{error} = q/Can't return data! Please, try later!/;
      $c->out(1);
    }
  }
  else {
    $c->stash->{status_code} = 401;
    $c->stash->{error} =
'Unauthorized! You need to make login to get the authentication key and pass it on Authentication header.';
  }
  return $ok;
}

sub is_valid {
  my ($string) = @_;
  return is_uuid($string);
}


sub default : Path {
  my ( $self, $c ) = @_;
  say "HERE IN Root::default";
  $c->res->content_type('application/json');
  $c->stash->{error}       = 'API resource not found!';
  $c->stash->{status_code} = '404';
  return $c->out;
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
}

=head1 AUTHOR

eokoe,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
