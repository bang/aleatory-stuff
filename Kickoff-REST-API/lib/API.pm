use common::sense;

package API;
use Moose;
use namespace::autoclean;
use DateTime;
use Catalyst::Runtime 5.80;
use Data::Dumper;
use Data::Printer colored => 1;
use JSON;
use API::DataTreatment;
use Log::Log4perl qw/get_logger/;
use JSON;

#Setting default values for environment variables

$ENV{OPENGATES_LOG_DIR} = '/tmp' if !defined($ENV{OPENGATES_LOG_DIR});
$ENV{OPENGATES_TIMEZONE} = 'local' if !defined($ENV{OPENGATES_TIMEZONE});
$ENV{CATALYST_DEBUG} = 1 if !defined($ENV{OPEN_LOG_DIR});
$ENV{API_NAME} = 'API' if !defined($ENV{API_NAME});


use Catalyst qw/
  -Debug
  ConfigLoader
  Static::Simple

  Authentication
  Authorization::Roles
  /;

extends 'Catalyst';

our $VERSION = '0.00011';

has treatment => ( is => 'rw', );

has logger => (is => 'ro',
               default => sub {
                  my $config = q(
log4perl.logger=INFO, LOGFILE
log4perl.logger2=ERROR, LOGFILE
log4perl.logger3=WARN, LOGFILE
log4perl.logger4=FATAL, LOGFILE
 
log4perl.appender.LOGFILE=Log::Log4perl::Appender::File
log4perl.appender.LOGFILE.filename=) . $ENV{OPENGATES_LOG_DIR} .q(/opengates.log
log4perl.appender.LOGFILE.mode=append
log4perl.appender.LOGFILE.layout=PatternLayout
log4perl.appender.LOGFILE.layout.ConversionPattern=[%d] - %m%n

                  );
                  Log::Log4perl->init(\$config);
                  return get_logger();
               }
              );


#Globals
our $TIME_ZONE = $ENV{OPENGATES_TIMEZONE} // 'America/Sao_Paulo';

__PACKAGE__->config(
  uploadtmp                                   => '/tmp',
  upload_dir                                  => '/tmp',
  time_zone                                   => 'America/Sao_Paulo',
  name                                        => 'API',
  disable_component_resolution_regex_fallback => 1,
  enable_catalyst_header                      => 1,

  'Plugin::Authentication' => {
    default => {
      class         => 'SimpleDB',
      user_model    => 'APIDB::Account',
      password_type => 'clear',

      #            password_hash_type => 'SHA-1',
    },
  },

  'View::JSON' => {

    expose_stash    => [ ('access-key','status_code', 'error', 'message', 'api-version', 'api-name', 'account', 'accounts', 'resource', 'group' ) ], # defaults to everything
    convert_blessed => 1,
    allow_blessed => 1,
  },

  'Plugin::Authorization::Roles' => {
    dbic => {
      role_class => 'APIDB::Role',
      user_role_user_field => 'account_id',
    },
  },

);

# STATIC METHOD to give localtime in a form of DateTime object
sub get_local_date {
  return DateTime->now( time_zone => $TIME_ZONE );
}

# Generic method to treat any data.
sub treat_data {
  my ( $self, $trait_name, $action, $data, $attr ) = @_;
  my ( $ok, $treat ) = ( 0, 0 );
  eval {
    $self->treatment(
      API::DataTreatment->new_with_traits(
        traits => [$trait_name],
        data   => $data,
        %{$attr},
      )
    );
  };

  #general errors
  if ($@) {
    my $trouble = $@;
    $trouble =~ s/ at.*$//;    #removes irrelevant information for api user.
    chomp $trouble;
    $self->stash->{error}       = $trouble;
    $self->stash->{status_code} = 400;
    $self->out(1);
  }    #errors on syntax, modules etc.
  else {
    my $profile_name = 'profile_' . $action;
    eval { $treat = $self->treatment->verify_params($action); };
    if ($@) {
      $self->stash->{error} = "Data treatment error! $@";
    }    #specific param errors(typical missing and invalid errors)
    elsif ( !$treat ) {
      my @Error;
      push @Error,
        {
        error_message => 'Invalid params!',
        params        => $self->treatment->invalid_params
        }
        if ( @{ $self->treatment->invalid_params } );

      push @Error,
        {
        error_message => 'Missing required params!',
        params        => $self->treatment->missing_params
        }
        if ( @{ $self->treatment->missing_params } );

      $self->stash->{error}       = \@Error;
      $self->stash->{status_code} = 400;
    }
    else {
      $ok = 1;
      $self->stash->{status_code} = 200;
    }
  }
  return $ok;
}

sub out : Local {
  my ( $self, $detach ) = @_;
  $detach = 0 if !defined $detach;
  my $sys_error = $@;
  my $status_code = $self->res->code;
  $status_code = $self->stash->{status_code}
    if defined( $self->stash->{status_code} )
    and $self->stash->{status_code};
  $status_code = 200 if !defined($status_code) or !$status_code;

  #this excludes useless garbage from error message. I don't know how to do this better yet
  if ( $self->stash->{error} && !ref( $self->stash->{error} ) ) {
    my $err = $self->stash->{error};
    $err =~ s/(\r|\n)//igo;
    $err =~ s/ at.*$//;
    $self->stash->{error} = $err;
    undef $err;
  }
  elsif ( defined( $self->stash->{status_code} )
    && $self->stash->{status_code} )
  {
    $status_code = $self->stash->{status_code};
  }

  $self->res->status($status_code);
  #populating default value in the stash to have it in the log
  $self->default_stash();


  if($detach){
    $self->stash->{'system-error'} = $sys_error if defined($sys_error) and $sys_error;
    $self->write_log('error');
    $self->detach;
  } 
  delete $self->stash->{error} if !defined($self->stash->{error});
  delete $self->stash->{error} if !defined($self->stash->{error});
  
  delete $self->stash->{message} if $self->stash->{error} and $self->stash->{status_code} != 200;
  $self->forward('View::JSON');

  #log request and response data(not all of them) 
  if($self->stash->{error}){
    $self->stash->{'system-error'} = $sys_error if defined($sys_error) and $sys_error;
    delete $self->stash->{message};
    $self->write_log('error');
  }
  else {
    $self->write_log('info');
  }
  say STDERR 'STASH: ' . p $self->stash if $ENV{CATALYST_DEBUG};
}

sub write_log {
  my ($self,$level,$msg) = @_;
  my $message;
  my $message_key_name = 'message';
  $message_key_name = 'error' if $level eq 'error'; 
  
  #populating default value in the stash to have it in the log
  $self->default_stash();

  if(defined($msg) && !ref($msg)){
    $message = $level eq 'error' ? { error => $msg }
                                 : { message => $msg };
  }
  elsif(!defined($msg)){
    $message = $level eq 'error' ? { error => $self->stash->{error} }
                                 : { message => $self->stash->{message}};
  }
  else {
    $message = $level eq 'error' ? { error => $msg }
                                 : { message => $msg };

  }

#Normally error objects from Catalyst has 'Exception' in your module reference names
#This is kind of precary, but works! Don't know how to do better yet.
  
  my $sys_error = $self->stash->{'system-error'} // ''; 
  
  if($sys_error and ref($sys_error) =~ /Exception/){
    my $e = $sys_error;
    $sys_error = $e->{msg};
    undef $e;
  }
  elsif($!){
    $sys_error = $!;
  }

  #Request info
  my $req = {
    path => $self->req->env->{PATH_INFO},
    host => $self->req->env->{HTTP_HOST},
    'server-port' => $self->req->env->{SERVER_PORT},
    'user-agent' => $self->req->env->{HTTP_USER_AGENT},
    'remote-addr' => $self->req->env->{REMOTE_ADDR},
  };

  my @Headers_names = $self->req->headers->header_field_names;
  my $headers;
  map{$headers->{$_} = $self->req->headers->header($_) if $_ !~ /authentication/i;}@Headers_names;
  $req->{headers} = $headers;
  undef $headers;
  
  my $request_info = encode_json($req) // '';
  my $response_info = $self->res->{body} // '';
  my $status_code = $self->stash->{status_code} // '';
  my $final_msg = "[$level] [$status_code] [request-info: $request_info] [response-info: $response_info]" ; 
  $final_msg .=  " [system-error: $sys_error]" if $sys_error;

  $self->logger->$level($final_msg);
}



sub default_stash {
  my ($self,) = @_;
  $self->stash->{status_code}   = $self->res->code;
  $self->stash->{'api-version'} = $VERSION;
  $self->stash->{'api-name'}    = $ENV{APP_NAME};

}


# Start the application
__PACKAGE__->setup();

=encoding utf8

=head1 NAME

API - Catalyst based application

=head1 SYNOPSIS

./start_server.sh

=head1 DESCRIPTION

This is the application base class. The main go is centralize things as log and data treatment calls for all controllers.

=head1 SEE ALSO

L<API::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Andre Carneiro L<mailto:andregarciacarneiro@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
