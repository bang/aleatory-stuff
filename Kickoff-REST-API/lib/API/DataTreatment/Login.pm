use strict;
use warnings;
use utf8;
use feature qw/say/;

package API::DataTreatment::Login;
use Moose::Role;
use Data::Validate::URI qw(is_uri);

has profile_login => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {
      email => {
        required   => 1,
        type       => 'Str',
        post_check => sub {
          my ($r,$ok) = (shift,0);
          use Email::Valid;
          my $value = $r->get_value('email');
          return 1 if Email::Valid->address($value); 
          $self->give_reason('email',q/E-mail address is invalid!/);        
          return 0;
        },
      },

      password => {
        required   => 1,
        type       => 'Str',
      },
    };
  }
);


has filters => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { ['trim'] },
);








1;
