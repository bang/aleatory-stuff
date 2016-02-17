use strict;
use warnings;
use utf8;
use feature qw/say/;

package API::DataTreatment::Account;
use Moose::Role;
use Data::Validate::URI qw(is_uri);
use Email::Valid;
use Data::Printer colored => 1;

has profile_create => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {

      email => {
        required   => 1,
        type       => 'Str',
        post_check => sub {
          return $self->default_email(shift); 
        },
      },   
      
      first_name => {
        required   => 1,
        type       => 'Str',
        post_check => sub {
          my $r = shift;
          my $value = $r->get_value('first_name');
          my $ok = $value =~ /^[A-Za-z]+$/ ? 1 : 0;
          $self->give_reason('first_name',q/Just the first name without spaces or special characters, please!/) if !$ok;        
          return $ok;
        },
      },

      last_name => {
        required   => 1,
        type       => 'Str',
        post_check => sub {
          my $r = shift;
          my $value = $r->get_value('last_name');
          my $ok = $value =~ /^[A-Za-z]+$/ ? 1 : 0;
          $self->give_reason('last_name',q/Just the last name without spaces or special characters, please!/) if !$ok;        
          return $ok;
        },
      },

      password => {
        required  => 1,
        type      => 'Str',
        post_check => sub {
          my ($r,$ok) = (shift,0);
          my $value = $r->get_value('password');
          $ok = $value =~ /^[A-Za-z0-9\!\@\#\$\%\*\_\-]{6,10}$/ ? 1 : 0;
          $self->give_reason('password',q/Password must have 6 to 10 alphanumeric characters with one or more of this special characters: !@#$%*_-/) if !$ok;        
          return $ok;
        },
      },
    };
  }
);



has profile_read_email => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {

      email => {
        required   => 1,
        type       => 'Str',
        post_check => sub {
          return $self->default_email(shift);
        },
      },     
    },
  },
);



has profile_read_id => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {

      id => {
        required   => 1,
        type       => 'Int',
      },
    
    },
  },
);


has profile_read_target => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {

      target => {
        required   => 1,
        type       => 'Str',
        post_check => sub {
          my $r = shift;
          my $value = $r->get_value('target');
          my $valid_targets = 'email, id or all';
          my $ok = $value =~ /^email|id|all$/ ? 1 : 0;
          $self->give_reason('target',qq/Parameter 'target' must be <$valid_targets>/) if !$ok;
          return $ok;
        },
      },
    },
  },
);



my %update_delete_profile = (
  is => 'rw',
  isa => 'HashRef',
  default => sub {
    my $self = shift;
    return {
      
      account_id => {
        required   => 1,
        type       => 'Int',
        post_check => sub {
          return $self->default_account_id(shift);
        },
      },
    },
  },
);

has profile_update => %update_delete_profile;

has profile_delete => %update_delete_profile;

has profile_activate => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {

      account_id => {
        required   => 1,
        type       => 'Int',
      },
      activation_key =>{
        required   => 1,
        type       => 'Str',
      },
    },
  },
);


has profile_bind_to_role => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {

      account_id => {
        required   => 1,
        type       => 'Int',
      },
      
      role => {
        required   => 1,
        type       => 'Str',
      },
    },
  },
);


has 'profile_reset-password' => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {
      email => {
        required   => 1,
        type       => 'Str',
        post_check => sub {
          return $self->default_email(shift); 
        },
      },
    },
  },
);

has 'profile_expire-all-password-keys' => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {
      account_id => {
        required   => 1,
        type       => 'Int',
        post_check => sub {
          return $self->default_account_id(shift);
        },
      },
    },
  },
);


has filters => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { ['trim'] },
);


has profile_send_activation_key => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {

      account_id => {
        required   => 1,
        type       => 'Int',
        post_check => sub {
          return $self->default_account_id(shift);
        },     
      },
    },
  },
);

####Default postchecks

sub default_email {
  my ($self,$r) = @_;
  my $value = $r->get_value('email');
  my $ok = Email::Valid->address($value) ? 1 : 0; 
  $self->give_reason('email',q/E-mail address is invalid!/) if !$ok;        
  return $ok; 
}

sub default_account_id {
  my ($self,$r) = @_;
  my $value = $r->get_value('account_id');
  my $ok = $value =~ /^\d+$/ ? 1 : 0; 
  $ok = 0 if $value <= 0;
  $self->give_reason('target',qq/Parameter 'account_id' must be a positive integer number/) if !$ok;
  return $ok; 
}



=head1 Testando o derived

TODO

profile => {
                target => {
                    type       => Str,
                    required   => 1
                },
                email => {
                    type       => EmailAddress,
                    required   => 0
                },
                id => {
                    type       => Int,
                    required   => 0
                }
            },
            derived => {
                data => {
                    required => 1,
                    fields   => [qw/ email id /],
                    deriver  => sub {
                        my ($r) = @_;
                        my $e = $r->get_value('email');
                        my $i = $r->get_value('id');
                        return $i ? $i : $e;
                    }
                }  
            }



=cut


1;
