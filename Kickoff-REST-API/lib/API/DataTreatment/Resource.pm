use strict;
use warnings;
use utf8;
use feature qw/say/;

package API::DataTreatment::Resource;
use Moose::Role;
use DDP colored => 1;
use Data::Validate::URI qw(is_uri);

has profile_create => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;
    return {
      #name1..N and path1..N are dynamically generated on BUILD according to value of 'uploads' attribute.
     
      group_id => {
        required   => 0,
        type       => 'Int',
      },

      image_url => {
        required   => 0,
        type       => 'Str',
        post_check => sub {
          my ($r,$ok) = (shift,0);
          my $value = $r->get_value('password');
          $ok = 0;
          $ok = 1 if is_uri($value);
          $self->give_reason('image_url',qq/'$value' is not a valid URI!/) if !$ok;        
          return 0;
        },
      },

      image_filepath => {
        required   => 0,
        type       => 'Str',
        #TODO how to test a valid file path?
      },
    
      description => {
        required   => 0,
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
      #TODO Estudar como resolver múltiplos campos dinâmicos.
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


sub BUILD {
  my ($self,) = @_;

  say p $self;

  #Generate profiles path1..N and name1..N according by Resource cont.
  my $pcreate = $self->profile_create;
  #$self->uploads($self->set_attr->{uploads});

  #If no uploads exists, path and type will never be checked. So it's necessary to force check this parameters.
  $self->uploads(1) if !defined($self->uploads) or !$self->uploads;
  
  #check types and paths according required uploads
  foreach my $i(1..$self->uploads){
    $pcreate->{'path' . $i} = {
                          required   => 1,
                          type       => 'Str',
                          post_check => sub {
                            $self->give_reason('path' . $i,qq/path must have a filename./);        
                          },
                        };
    
    $pcreate->{'type' . $i} = {
        required   => 1,
        type       => 'Str',
        post_check => sub {
          my ($r,$ok) = (shift,0);
          my $value = $r->get_value('type' . $i);
          my $valid_types = 'text|csv|json';
          $ok = 1 if $value =~ /^($valid_types)/;
          $self->give_reason('type' . $i,qq/Parameter 'type' must be <$valid_types>/);        
          return $ok;
        },
      };
  }

  $self->profile_create($pcreate);
  



  undef $pcreate;

}







1;
