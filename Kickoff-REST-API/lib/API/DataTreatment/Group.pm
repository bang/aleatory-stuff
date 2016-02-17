use strict;
use warnings;
use utf8;
use feature qw/say/;

package API::DataTreatment::Group;
use Moose::Role;
use DDP colored => 1;
use Data::Validate::URI qw(is_uri);

has profile_create => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {
     
      name => {
        required   => 1,
        type       => 'Str',
      },

#      image => {
#        required   => 0,
#        type       => 'Str',
#        #TODO how to test a valid file path?
#      },
    
      description => {
        required   => 1,
        type       => 'Str',
      },   
    


    };
  }
);



has profile_read => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {
      
      target => {
        required   => 1,
        type       => 'Str',
        post_check => sub {
          my ($r,$ok) = (shift,0);
          my $value = $r->get_value('target');
          my $valid_targets = 'all|uuid';
          $ok = 1 if $value =~ /^($valid_targets)/;
          $self->give_reason('target',qq/Parameter 'target' must be <$valid_targets>/);
          return $ok;
        },
      },
    },
  },
);




has profile_update => ( 
  is => 'rw',
  isa => 'HashRef',
);



has profile_delete => ( 
  is => 'rw',
  isa => 'HashRef',
);



has filters => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { ['trim'] },
);


has uploads => (
  is => 'rw',
  isa => 'Int',
  required => 0,
);










1;
