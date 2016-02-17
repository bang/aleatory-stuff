package API::Controller::API::Resource;
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




our $RESOURCE = 'Resource';

sub setup :Chained('/base') :PathPart('resource') :CaptureArgs(0) {
  my ($self,$c) = @_;
  
  say "RESOURCE - USER: " . ref $c->user;

}


sub create :Chained('setup') :PathPart('') :Args(0) POST {
  my ($self,$c,$uploads ) = @_;
  my $dt = API::get_local_date();
  my $model = $c->model('APIDB::Resource');
  my ($msg,$umsg) = ('','');
  my ($message_key,$message) = ('message','');
  my (@Error, @Inserted);
  
  #getting files paths to upload.
  my @Paths;
  map{push @Paths, $_ if $_ =~ /^path\d+$/}keys(%{$c->req->params});
  my @SPaths = sort @Paths;
  @Paths = @SPaths;
  @SPaths = ();
  
  if($c->treat_data('Resource','create',$c->req->params, {uploads => scalar(@Paths)}, ) ){
    my ($group_id,$img_url,$img_filepath,$description) = 
                                           map{$c->req->params->{$_}}qw/group_id img_url img_filepath description/ ;

      say 'AKI...' . p @Paths;
    #TODO study the possibility to make this under fork
    my $i = 1;
    foreach my $pathfield(@Paths){
      #First of all: UPLOAD!
      my $resource_uuid = '';
      if(!($resource_uuid = $self->upload($c,$pathfield)) ){
        $umsg = q/Sorry! But was not possible to make upload in your source file./;
        push @Error,{ error_message => 'problems with upload!',
                      file => $c->req->params->{$pathfield},
                    };
      }
      else {
        say "UPLOAD OK!";    
        #Write on RDBMS
        my $dt = API::get_local_date();
        my $now = $dt->dmy('/') . ' ' . $dt->hms(':');
        my $rs = undef;
        
        #Extracting name from path
        my $path = $c->req->params->{'path' . $i};
        my @Components = split /\//,$path;
        my $name = $Components[$#Components];

        #Extracting type
        my $type = $c->req->params->{'type' . $i} 
                    or undef; #database take care of this in case of NULL

        eval {$rs = $model->create({
              name => $name,
              description => $description,
              resource_type_name => $type,
              id => $resource_uuid,
              address => undef,#$address,
              img_url => $img_url,
              last_access => $now ,
              group_id => $group_id,
              resource_type_name => $type,
          });
        };
        if($@) {
          $msg = $@;
          $umsg = q{Sorry, but your request can't be performed! Please, try later!};
          say "\n\nERROR_MSG: $@\n\n";
          $message_key = 'error';
          if($@ =~ /resource_resource_type_name_fkey/){
            $umsg = qq{Sorry, but datatype '$type' is not supported! See 'Data types' in API documentation session for more details! };
            push @Error,{error_message => $umsg};
            $c->stash->{status_code} = 400;
          }
          elsif($@ =~ /duplica|uq_resource_name_resourcetypename/){
            $umsg = qq{This resource ['$name'] is already in!};
            push @Error, {  resource => $name,
                            error_message => qq/Resource '$name' is uploaded already!/
                        };
            $c->stash->{status_code} = 400;
          }
          else {
            $c->stash->{status_code} = 500;
            push @Error,{error_message => q/Sorry, but was not possible to perform your request! Please, try later!/};
          }
        }
        elsif( !$self->bind_to_user($c,$rs) ) {
          $c->stash->{error} = q{Sorry, but it's not possible to bind this resource to user};
          $c->stash->{status_code} = 500;
          #TODO cleanup database
        }
        else {
          push @Inserted,$name;
        }
      }
      $i++;
    }
    $c->stash->{inserted} = \@Inserted;

  }
  if(@Error){
    $c->stash->{status_code} = 400;
    $c->stash->{error} = \@Error;
  }
  else {
    $c->stash->{message} = 'Resource insert ok!';
    $c->stash->{inserted} = \@Inserted;
  }
  
  $c->out;
}


sub bind_to_user {
  my ($self,$c,$rs) = @_;
  my $ok = 0;
  my $model = $c->model('APIDB::AccountResource');
  eval{
    $model->create({
          account_id    => $c->user->id,
          resource_id   => $rs->id,
      });
  };
  if($@){
    say "ERROR: $@";
  }
  else {
    $ok = 1;
  }
  return $ok;
}


sub read :Chained('setup') :PathPart('') :Args(1) GET {
  my ($self,$c,$target) = @_;
  use DDP;
  say "Em read...." . p $c->user;
  my $params = $c->req->params();
  my $target_value = $params->{$target} || '';
  my ($message,$status_code) = ('unknown',400);
  my $message_key = 'message';
  my @Resources = ();
  $target = 'all' if !defined $target or !$target;
  $params->{target} = $target;
  
  if($c->treat_data('Resource','read',$c->req->params)){
    my @R = ();
    
    if( $target eq 'all'){
      eval{@Resources = $c->model('APIDB::Resource')->all };
      if($@){

      }
    }
    
    else {
      $target = 'id' if $target eq 'uuid';
      eval{
        @Resources = $c->model('APIDB::Resource')->search( {$target => $target_value
                                                            
                                                            } );
      };
      if($@){

      }
    }

    if($@){
      $message = q/Can't find resource! Please, try later!/ ;
      $message_key = 'error';
      $status_code = 'server_error';
      @Resources = ();
    }
    else {
      $message = 'OK';
    }
  }
 
  my @R;
  foreach my $row(@Resources){
    my %h =$row->get_columns;
    push @R,\%h;
  }
  @Resources = @R if scalar(@Resources) > 0;
  @R = ();
  
  $c->stash->{resources} = \@Resources;
  $c->stash->{$message_key} = $message
    if defined($message) and $message;
  $c->out;

}


#sub update :Chained('setup') :PathPart('') :Args(1) PUT {
#  my ($self,$c) = @_;
#}
#
#
#sub delete :Chained('setup') :PathPart('') :Args(1) DELETE {
#  my ($self,$c) = @_;
#  
#  $c->res->body(to_json({msg => 'test delete'})  );
#}
#
#
sub upload {
  my($self,$c,$path) = @_;
  my( $upload, $uuid ) = (0,'');
  my $source = $c->req->params->{$path};
  say "UPLOAD_DIR: " . $c->config->{upload_dir};
  if($source){
    eval{$upload = $c->req->upload($path);};
    say "UPLOAD CRAP: ". Dumper $upload;
    say "TARGET TO UPLOAD ==> ". Dumper $source;
    if( defined $upload && $upload){
      say "UPLOAD INSTANCE OK! :D";
      my @Parts = split /\//,$source;
      my $file = $Parts[$#Parts];
      say "FILE: $file";
      say "UPLOAD OBJ: " . Dumper $upload;
      my $destination = join('/', $c->config->{upload_dir},$file);
      say "COPY TO: " . Dumper $destination;
      $upload->copy_to( $destination );
      $uuid = UUID::Tiny::create_uuid_as_string(UUID_V4) if -e $destination;
    }
    else {
      say "UPLOAD FAIL! :( $! $@";
      $uuid = '';
    }
  }
  else {
    say "NO SOURCE PATH!";
    $uuid = '';
  }
  return $uuid;
}


=encoding utf8

=head1 NAME

API::Controller::API::Resource - Resource endpoints for Opengates API

=head1 DESCRIPTION

CRUD controller for resource entity(table). 

=head1 RESOURCE CRUD ENDPOINTS

=head2 Create resource (POST) - /api/resource/NAME/DESCRIPTION/TYPE

This endpoint has three mandatory arguments:

=over

=item * Str name: Name of resource;

=item * Str description: Little text content about the resource;

=item * Str type: It's a string that contains a alias for MIME content-type. For now just csv and text are supported.

=back

Return formats having http response code as reference:

=over

=item * 200: 

=item * 500:

=item * 406:


=back



=head2 Read resource (GET) - /api/resource/TARGET or /api/resource/TARGET

=head2 Update resource (PUT) - /api/resource/TARGET

=head2 Delete resource (DELETE) - /api/resource/TARGET

=head1 AUTHOR

André Garcia Carneiro L<andregarciacarneiro@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
