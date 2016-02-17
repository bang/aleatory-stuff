package API::Controller::API::Logout;
use common::sense;
use Moose;
use namespace::autoclean;
use JSON;
use Data::Dumper;
use Data::Printer colored => 1;
use API;
use UUID::Tiny;
use feature qw/say/;

BEGIN { extends 'Catalyst::Controller'; }




our $RESOURCE = 'Logout';

sub setup :Chained('/') :PathPart('logout') :CaptureArgs(0) {
  my ($self,$c) = @_;

}


sub create :Chained('setup') :PathPart('') :Args(0) POST {
  my ($self,$c,$uploads ) = @_;
  $c->logout;
  $c->stash->{message} = q/You're not logged anymore!/;
  $c->out;
}


=encoding utf8

=head1 NAME

API::Controller::API::Logout - Logout endpoints for Opengates API

=head1 DESCRIPTION

CRUD controller for resource entity(table). 

=head1 RESOURCE CRUD ENDPOINTS

=head2 Create resource (POST) - /api/logout

Parameters:

There is no parameters for this endpoint

=head1 AUTHOR

André Garcia Carneiro L<andregarciacarneiro@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
