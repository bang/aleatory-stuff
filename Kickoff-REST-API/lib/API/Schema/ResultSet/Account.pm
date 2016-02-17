package API::Schema::ResultSet::Account;

use strict;
use warnings;
use feature qw/say/;
use Moose;
use namespace::autoclean;

use Data::Printer colored => 1;
extends 'DBIx::Class::ResultSet';

sub add {
  my ($self,$c) = @_;
  my ($rs,$account,) = (undef,undef,);
  
  if($c->treat_data('Account','create',$c->req->params, ) ){
    eval{ $rs = $self->create( $c->req->params ); };
    if($@){
      $c->stash->{error} = q/Can't create account right now! Please, try later!/;
      if($@ =~/duplica/){
        $c->stash->{error} = 'This account is already exists! Maybe you should try another email?';
        $c->stash->{status_code} = 400;
      }
      else {
        $c->stash->{error} = q/Can't create account right now! Please, try later!/;
        $c->stash->{status_code} = 500;
        $c->out(1);
      }
    }
    else {

      #If it's allright don't need error key in the stash.
      delete $c->stash->{error};
      
      #mounting account hash data TODO Maybe I should let DBIx::Class make this by 'inflate' or something like that.
      map{$account->{$_} = $rs->$_ if $_ !~ /password/;} keys %{$c->req->params};
      $account->{id} = $rs->id;
      
      #generating activation key
      my $activation_key = $c->model('APIDB::ActivationKey');
      $activation_key->add($c,$account->{id});
      undef $activation_key;
    
      #giving default role(members)
      $self->bind_to_role($c,$account->{id},'members');
    }
  }
  return $account;
}


sub bind_to_role {
  my ($self,$c,$account_id,$role) = @_;
  my $ok = 0;
  if($c->treat_data('Account','bind_to_role',{account_id => $account_id,
                                              role => $role,
                                            }, ) ){
    my $model = { role => $c->model('APIDB::Role'),
                  account_role => $c->model('APIDB::AccountRole'),
                };
    #get role id
    my $rs;
    eval{($rs) = $model->{role}->search({role => $role});};
    if($@){
      $c->stash->{status_code} = 500;
      $c->stash->{error} = q/Problems to find proper role! Please, try later!/;
      $c->out(1);
    }
    elsif(!defined($rs) || !$rs){
      $c->stash->{status_code} = 400;
      $c->stash->{error} = qq/Role '$role' was not found!/;
    }
    else {
      my $role_id = $rs->id;
      eval{$model->{account_role}->create({account_id => $account_id,
                                           role_id_id => $role_id,
                                        })
      };
      if($@ && $@ !~ /duplica/){
        $c->stash->{status_code} = 500;
        $c->stash->{error} = q/Unfortunately your request couldn't be performed! Please, try later!/;
        $c->out(1);
      }
      else {
        $ok = 1;
      }
    }
  }
  return $ok;
}



sub fetch {
  my ($self,$c) = @_;
  my @Accounts;
  my @Stash_accounts;
  my $params = $c->req->params;
  $params->{ suspended_at} = undef ;
  eval{
    @Accounts = $self->search( $params );
  };
  if($@){
    $c->stash->{error} = q/Can't bring up accounts right now! Please, try later!/;
    $c->stash->{status_code} = 500;
  }
  elsif(!@Accounts){
    $c->stash->{error} = q/No accounts found with the parameters sent!/;
    $c->stash->{status_code} = 400;
  }
  else {
    foreach my $rs(@Accounts){
      my $account;
      map{ $account->{$_} = $rs->$_ if defined($_) and $_ and $_ !~ /target/ }
            qw/email first_name last_name active/;
      my ($c_dt, $s_dt) = ($rs->created_at,$rs->suspended_at);
      my ($created_at,$suspended_at);
      $account->{created_at} = join( ' ' ,$c_dt->ymd('/'), $c_dt->hms(':')  ) 
                                                      if ref($c_dt) eq 'DateTime';

      $account->{suspended_at} = join( ' ' ,$s_dt->ymd('/'), $s_dt->hms(':')  ) 
                                                      if ref($s_dt) eq 'DateTime';

      push @Stash_accounts, $account;
      $c->stash->{accounts} = \@Stash_accounts;
    }
  }
  @Accounts = ();
  return \@Stash_accounts;
}


sub activate {
  my ($self,$c) = @_;
  my ($ok,$params) = (0,$c->req->params);
  my $activation_key_model = $c->model('APIDB::ActivationKey');
  my ($key,$account_id) = ( $params->{activation_key},
                            $params->{account_id},
                            );
  if( $c->treat_data('Account','activate',$params ) ){
    my $rs;  
    eval{ ($rs) = $activation_key_model->search({ account_id     => $params->{account_id},
                                                  activation_key => $params->{activation_key},
                                                  expired_at     => { '>' => 'now()' },
                                                });
    };
    if($@){
      $c->stash->{error} = q/Can't activate account right now! Please, try later!/;
      $c->stash->{status_code} = 500;
    }
    elsif(!$rs) {
      $c->stash->{error} = q/Invalid activation key!/;
      $c->stash->{status_code} = 400;
    }
    else {
      #Updating user
      eval{$self->search({id => $account_id})->update({active => 1});};
      if($@){
        $c->stash->{error} = q/Can't activate account right now! Please, try later!/;
        $c->stash->{status_code} = 500;
        $c->out(1);
      }
      else {
        $c->stash->{message} = qq/The account '$account_id' activation was succeeded!/;
      }
    }
  }
  return $ok;
}


sub save {
  my ($self,$c,$account_id) = @_;
  my $params = $c->req->params;
  
  if( $c->treat_data('Account','update',$params, ) ){
    eval{ $self->search->({ id => $account_id })->update( $params ) };
    if($@){
      $c->stash->{error} = q/Can't update account right now! Please, try later!/;
      $c->stash->{status_code} = 500;
      $c->out(1);
    }
    else {
      $c->stash->{message} = 'OK';
      $c->stash->{status_code} = 200;
    }
  }
}


sub del {
  my ($self,$c,$account_id) = @_;
  my $params = $c->req->params;
  $params->{account_id} = $account_id;  
  eval{$c->assert_user_roles( qw/superuser/ );}; 
  
  if($@){
    $c->stash->{error} = q/Can't retrieve account data!/;
    $c->stash->{status_code} = 400;
  }
  elsif($c->treat_data('Account','delete',$params, ) ){
    eval{ $self->search->({ id => $account_id })->delete };
    if($@){
      $c->stash->{error} = q/Can't delete account right now! Please, try later!/;
      $c->stash->{status_code} = 500;
      $c->out(1);
    }
    else {
      $c->stash->{message} = 'OK';
      $c->stash->{status_code} = 200;
    }
  }
}


sub is_active {
  my ($self,$c,$account_id) = @_;
  my $active = 0;
  my $account = $self->fetch($c,$account_id);
  if(!defined($account) || !$account){
    $c->stash->{error} = q/This account doesn't exists!/;
    $c->stash->{status_code} = 400;
  }
  else {
    $active = $account->{active} ? 1 : 0;
  }
  return $active;
} 


sub reset_password {
  my ($self,$c,$email ) = @_;
  my $params = $c->req->params;
  my $password_key = '';
  my $rs;
  if($c->treat_data('Account','reset-password',$params, ) ){
    #checking e-mail
    eval{($rs) = $self->search({ email => $email}); };
    if($@){
      $c->stash->{error} = q/Can't retrieve data right now! Please, try later!/;
      $c->stash->{status_code} = 500;
      $c->out(1);
    }
    elsif(!defined($rs) || !$rs || !$rs->in_storage){
      $c->stash->{error} = q/email not found/;
      $c->stash->{status_code} = 400;
    }
    elsif(!$rs->active){
      $c->stash->{error} = q/Unauthorized! The account from this e-mail is innactive!/;
      $c->stash->{status_code} = 401;
    }
    elsif(defined($rs->suspended_at)){
      $c->stash->{error} = q/Unauthorized! The account from this e-mail is suspended!/;
      $c->stash->{status_code} = 401;
    }
    else {
      my $account_id = $rs->id;
      my $model = $c->model('APIDB::PasswordKey');
      #first of all. expire all other keys!
      $self->expire_all_password_keys($c,$account_id);
      eval{$rs = $model->create({account_id => $account_id});};
      if($@){
        $c->stash->{error} = q/Can't reset password right now! Please try later!/;
        $c->stash->{status_code} = 500;
        $c->out(1);
      }
      else {
        my $password_id = $rs->id;
        eval{($rs) = $model->search({id => $password_id})};
        if($@){
          $c->stash->{error} = q/Can't retrieve data right now! Please try later!/;
          $c->stash->{status_code} = 500;
          $c->out(1);
        }
        else {
          $password_key = $rs->password_key;
        }
      }
    }
  }
  return $password_key;
}


sub expire_all_password_keys {
  my ($self, $c, $account_id) = @_;
  my $ok = 0;
  if($c->treat_data('Account','expire-all-password-keys', {account_id => $account_id} ) ){
    my $model = $c->model('APIDB::PasswordKey');
    eval{$model->search({account_id => $account_id})->update({ 'duration' => \'tstzrange(lower(duration),now())'})};
    if($@){
      $c->stash->{error} = q/Can't change password key right now!/;
      $c->stash->{status_code} = 500;
      $c->out(1);
    }
    else {
      $ok = 1;
    }
  }
  return $ok;
}











__PACKAGE__->meta->make_immutable;

1;

















