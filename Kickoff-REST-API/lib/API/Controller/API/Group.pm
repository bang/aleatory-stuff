use feature qw/say/;
package API::Controller::API::Group;
use Moose;
use namespace::autoclean;
use Data::Printer colored => 1;

BEGIN { extends 'Catalyst::Controller'; }



sub setup :Chained('/base') :PathPart('group') :CaptureArgs(0) {
  my ($self,$c) = @_;

}


sub create :Chained('setup') :PathPart('') :Args(0) POST {
  my ($self,$c) = @_;
  my $params = $c->req->params;

  if($c->treat_data('Group','create',$c->req->params,)  ){
    my $model = $c->model('APIDB::Group');
    my $rs;
    eval{
      $rs = $model->create( $params );
    };

    if($@){
      $c->stash->{error} = q/Can't create group right now! Please, try later!/;
      $c->stash->{status_code} = 500;
      if($@ =~ /duplica/){
        $c->stash->{error} = q/This group already exists!/;
        $c->stash->{status_code} = 400;
      }
    }
    else {
      my $group_data;
      map{ $group_data->{$_} = $rs->$_ } qw/name description/;
      $c->stash->{'group'} = $group_data;
      $c->stash->{'message'} = 'OK!';
    }
  }
  $c->out;
}


sub read :Chained('setup') :PathPart('') :Args(0) GET {
  my ($self,$c) = @_;

  $c->stash->{status_code} = 404;
  $c->stash->{error} = 'Not implemented yet!';

}


sub update :Chained('setup') :PathPart('') :Args(0) PUT {
  my ($self,$c) = @_;

  $c->stash->{status_code} = 404;
  $c->stash->{error} = 'Not implemented yet!';

}


sub delete :Chained('setup') :PathPart('') :Args(0) DELETE {
  my ($self,$c) = @_;

  $c->stash->{status_code} = 404;
  $c->stash->{error} = 'Not implemented yet!';
}






=encoding utf8

=head1 NAME

API::Controller::API::Group - Catalyst Controller

=head1 DESCRIPTION

Opengates group controller.

=head1 ACTIONS



=head1 AUTHOR

carneirao,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
