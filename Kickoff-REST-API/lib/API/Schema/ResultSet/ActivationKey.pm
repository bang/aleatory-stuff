package API::Schema::ResultSet::ActivationKey;

use strict;
use warnings;
use feature qw/say/;
use Moose;
use namespace::autoclean;

extends 'DBIx::Class::ResultSet';


sub add {
  my ($self,$c,$account_id) = @_;
  my $key = $self->random_key(); 
  
  #expiring possibly old keys
  $self->expire_old_keys($c,$account_id);
  #insert new key 
  eval{ $self->create({ activation_key => $key, 
                        account_id => $account_id,
                      }); 
  };
  if($@){
    $c->stash->{error} = q/Can't create activation code right now! Please, try later!/;
    $c->stash->{status_code} = 500;
  }
  else {
    $c->stash->{message} = q/Please, check your e-mail and follow the instructions to activate your account!/;
    $c->stash->{status_code} = 200;
    #TODO create email template to activate code and create the function to build and enqueue and send through e-mail.
  }
  return $key;
}


sub expire_old_keys {
  my ($self,$c, $account_id) = @_;
  my $ok = 0;
  
  #Expiring old keys of this account_id 
  eval{
    $self->search({account_id => $account_id})->update({ expired_at => \'now()' });
  };
  if($@){
    $c->stash->{error} = q/Can't expire activation code right now! Please, try later!/;
    $c->stash->{status_code} = 500;
  }
  else {
    $ok = 1;
    $c->write_log('info',"new activation key added for account '$account_id'");
  }
  return $ok;
}


sub random_key {
  my ($self,) = @_;
  my $key;
  foreach my $char(1..60){
    my $choice = int(rand(3));
    if(!$choice) {
      my @Letters = qw/a b c d e f g h i j k l m n o p q r s t u v w x y z 
                       A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
      $key .= $Letters[int(rand($#Letters))];
    }
    elsif($choice == 1){
      my @Numbers = (1,2,3,4,5,6,7,8,9,0);
      $key .= $Numbers[int(rand($#Numbers))];
    }
    else {
      my @Special_chars = ('!', '#', '-', '=', '+' );
      $key .= $Special_chars[int(rand($#Special_chars))];
    }
  }
  return $key;
}




__PACKAGE__->meta->make_immutable;
1;

