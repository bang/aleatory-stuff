use feature qw/say/;
package API::Controller::API::Account;
use Moose;
use namespace::autoclean;
use Data::Printer colored => 1;
use FindBin qw/$Bin/;
say "BIN: $Bin";
use lib "$Bin/../lib/Jobs/lib";
use Jobs;

BEGIN { extends 'Catalyst::Controller'; }

=encoding utf8

=cut

has email_worker => (
                is => 'ro',
                default => sub {
                  return Jobs->new_with_traits( traits => ['Email'],
                                                type => 'Email',
                                                );
                },
);


sub setup :Chained('/base') :PathPart('account') :CaptureArgs(0) {
  my ($self,$c) = @_;
    
}

sub create :Chained('/') :PathPart('account') :Args(0) POST {
  my ($self,$c) = @_;
  my $model = $c->model('APIDB::Account');
  my $new_account = $model->add($c);
  if($c->stash->{status_code} == 200){
    $self->send_activation_key($c,$new_account->{id}) if $new_account;
    undef $model;
    $c->stash->{account} = $new_account;
  }
  $c->out;
}

sub read :Chained('setup') :PathPart('') :Args(1) GET {
  my ($self,$c,$target) = @_;
  my $params = $c->req->params;
  #gathering permission and essential user information
  my ($superuser_permission, $members_permission,$active,$suspended) = ( $c->check_user_roles(qw/superuser/) || 0,
                                                      $c->check_user_roles(qw/members/) || 0,
                                                      $c->user->active,
                                                      $c->user->suspended,
                                                    );
  if(!$active){
    $c->stash->{status_code} = 401;
    $c->stash->{error} = q/Unauthorized! This account was innactivated! Please, contact the support!/;
  }
  elsif(defined($suspended)){
   $c->stash->{status_code} = 401;
   $c->stash->{error} = q/Unauthorized! This account is suspended!/;
  }
  elsif($target eq 'all' && !$superuser_permission){
    $c->stash->{status_code} = 401;
    $c->stash->{error} = q/Unauthorized! You need superuser privileges to do that!/;
  }
  else {
    #setting data treatment profile.
    my $treat_profile = 'read_' . $target if $target =~ /email|id/;
    my $value = $params->{$target};
    $params = { target => $target,
                   $target => $value
              };
    
    if( $c->treat_data('Account','read_target', {target => $target}) &&
        $c->treat_data('Account',$treat_profile, $params) ){
        
      #checking permissions if data is ok 
      if( !$members_permission ){
        $c->stash->{status_code} = 401;
        $c->stash->{error} = q/Unauthorized! Something is very wrong! You're logged, but don't have permission to access your account! Please, contact the support!/;
      }
      elsif( ($target eq 'id' && $c->user->id ne $value) ||  
             ($target eq 'email' && $c->user->email ne $value) 
        ){
        $c->stash->{status_code} = 401;
        $c->stash->{error} = q/Unauthorized! You can just access your account!/;
      }
      else {
        my $model = $c->model('APIDB::Account');
        $model->fetch($c);
      }
    }
  }
  $c->out;
}


sub update :Chained('setup') :PathPart('') :CaptureArgs(1) PUT {
  my ($self,$c,$account_id) = @_;
  my $params = $c->req->params;
  my ($superuser_permission, $members_permission,$active,$suspended) = ( $c->check_user_roles(qw/superuser/) || 0,
                                                      $c->check_user_roles(qw/members/) || 0,
                                                      $c->user->active,
                                                      $c->user->suspended,
                                                    );
  if( !$active ){
    $c->stash->{status_code} = 401;
    $c->stash->{error} = q/Unauthorized! This account was innactivated! Please, contact the support!/;
  }
  elsif( defined($suspended) ){
   $c->stash->{status_code} = 401;
   $c->stash->{error} = q/Unauthorized! This account is suspended!/;
  }
  elsif( $account_id != $c->user->id && !$superuser_permission ){
    $c->stash->{status_code} = 401;
    $c->stash->{error} = q/Unauthorized! You need superuser privileges to change an account that is not yours!/;
  }
  elsif( !$c->user_check_roles( qw/members/ ) && $account_id == $c->user->id ) { 
    
    #user can alter your own account, except the fields suspended and active This is just for superuser!
    if( ( defined($params->{suspended_at}) && $params->{suspended_at} ) ||
        ( defined($params->{active}) && $active )
      ) {
      $c->stash->{status_code} = 401;
      $c->stash->{error} = q/Unauthorized!/;
    }
    else {
      my $model = $c->model('APIDB::Account');
      $model->save($c,$account_id);
    }
  }
  $c->out;
}


sub delete :Chained('setup') :PathPart('') :CaptureArgs(1) DELETE {
  my ($self,$c,$account_id) = @_;
  my $model = $c->model('Account');
   my ($superuser_permission, $active) = ( $c->check_user_roles(qw/superuser/) || 0,
                                           $c->user->active,
                                         );
  if(!$active){
    $c->stash->{status_code} = 401;
    $c->stash->{error} = q/Unauthorized! This account is innactive! Please, contact the support!/;
  } 
  elsif( !$c->user_check_roles(qw/superuser/) ){
    $c->stash->{error} = q/Unauthorized! You need superuser privileges to do that!/;
    $c->stash->{status_code} = 401;
  }
  else {
    $model->del($c,$account_id);  
  }
}


sub send_activation_key :Chained('/') :PathPart('account/send-activation-key') :Args(0) POST {
  my ($self,$c,$account_id) = @_;
  $account_id = $c->req->params->{account_id} if !defined($account_id);

  if($c->treat_data('Account','send_activation_key',{account_id => $account_id}, ) ){
    my $model = $c->model('APIDB::ActivationKey');  
    #TODO check if it's ok send another key(if exists). 
    
    #creating new activation key
    my $new_key = $model->add($c,$account_id);

    if(!$new_key){
      $c->stash->{status_code} = 500;
      $c->stash->{error} = "The new activation key couldn't be created!";
      $c->write_log('error',q/new activation key is empty!/); 
    }
    else {
      my $model = $c->model('APIDB::Account');
      my ($account) = $model->search({id => $account_id});
#      $self->email_worker->add({
#        header => { From => 'support@opengates.com.br',
#                     To => $account->email,
#                     Subject => 'Teste suporte',
#                   },
#        template => 'test_activation_key.tt',
#        template_vars => { name => join(' ',$account->first_name, $account->last_name),
#                           activation_key => $new_key,
#                         },
#      });
    }
  }
  $c->out;
}

sub activate :Chained('/') :PathPart('account/activate') :Args(0) POST {
  my ($self,$c) = @_;
  my $model = $c->model('APIDB::Account');
  $model->activate($c);
  $c->out;
}


sub reset_password :Chained('/') :PathPart('account/reset-password') :Args(0) POST {
  my ($self,$c) = @_;
  my $params = $c->req->params;
  my $model = $c->model('APIDB::Account');
  my $password_key = '';
  $password_key = $model->reset_password($c,$params->{email});
  say STDERR "PASSWORD_KEY: $password_key";
  if(defined($password_key) and $password_key ) {
    $self->email_worker->add({
        header => { From => 'support@opengates.com.br',
                     To => $params->{email},
                     Subject => 'Teste suporte',
                   },
        template => 'test_password_reset.tt',
        template_vars => { password_key => $password_key, },
    }); 
    $c->stash->{message} = q/A message was sent to e-mail address indicated on 'email' parameter!/;
  } 

  $c->out;
}




=head1 NAME

API::Controller::API::Account - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS



=head1 AUTHOR

carneirao,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
