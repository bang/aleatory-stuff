package API::DataTreatment;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::clean;
use feature qw/say/;
use DDP colored => 1;
use Data::Verifier;

with 'MooseX::Traits';

has '+_trait_namespace' => ('default' => 'API::DataTreatment');

has data => (is => 'rw',
              required => 1,
           );

has valid_params => ( is => 'rw',
                    isa => 'ArrayRef',
                );

has invalid_params => ( is => 'rw',
                    isa => 'ArrayRef',
                );

has missing_params => ( is => 'rw',
                        isa => 'ArrayRef'
                    );

has reasons => ( is => 'rw',
                  isa => 'HashRef',
                  default => sub { return {} },
              );

has derived => ( is => 'rw',
                );


sub give_reason {
  my ($self,$field,$message) = @_;
  my $reasons = $self->reasons;
  $reasons->{$field} = $message;
  $self->reasons($reasons);
}

sub cleanup_reasons {
  my ($self);
  $self->reasons({});
}

sub verify_params {
  my ($self,$action) = @_;
  my ($ok, $profile_action) = (0,'profile_' . $action);
  
  my %verifier_params = (
                  filters => $self->filters,  
                  profile => $self->$profile_action,
                );
  
  #TODO estudar isso melhor... $verifier_params{derived} = $self->derived if defined($self->derived) and $self->derived;

  my $verifier = Data::Verifier->new( %verifier_params );
  
  my $data = $self->data;
  my $results = $verifier->verify($data);
  my (@Valid,@Invalid,@Missing);
  
  foreach my $k(keys($self->$profile_action) ){
    if($results->is_missing($k)){
      push @Missing,$k;
    }
    elsif( $results->is_invalid($k)){
      push @Invalid,{$k =>{content => $data->{$k},
                           reason => $self->reasons->{$k},
                     }};
    }
    else{
      push @Valid,{$k => $data->{$k} };
    }
  }
  
  if($ENV{CATALYST_DEBUG}){
    say "Invalid: " . p @Invalid;
    say "Missing: " . p @Missing;
  }

  undef $data;
  undef $results;
  $self->valid_params(\@Valid);
  $self->invalid_params(\@Invalid);
  $self->missing_params(\@Missing);
  $ok = 1 if !scalar(@Invalid) and !scalar(@Missing);
  
  return $ok;
}


__PACKAGE__->meta->make_immutable;
1;
