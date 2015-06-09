package Plack::Middleware::Timeout;

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(timeout response);
use Plack::Request;
use Plack::Response;
use Scope::Guard ();
use Time::HiRes qw(alarm time);

our $VERSION = '0.06';

sub _get_alarm_subref {
    my $self = shift;

   my $timeout = $self->timeout || 120;
   return ref($timeout) eq 'CODE' ? $timeout : sub { alarm($timeout) };
}

sub call {
    my ( $self, $env ) = @_;

    my $alarm_msg = 'Plack::Middleware::Timeout';
    local $SIG{ALRM} = sub { die $alarm_msg };

    my $time_started = 0;
    eval {

        $time_started = time();
        $self->_get_alarm_subref->();

        my $guard = Scope::Guard->new(sub {
            alarm 0;
        });

        return $self->app->($env);

    } or do {
        my $request        = Plack::Request->new($env);

        my $response = Plack::Response->new(408);
        if ( my $build_response_coderef = $self->response ) {
            $build_response_coderef->($response,$execution_time);
        }
        else {
            # warn by default, so there's a trace of the timeout left somewhere
            warn sprintf
              "Terminated request for uri '%s' due to timeout (%ds)",
              $self->timeout;
        }

        return $response->finalize;
    };
}

1;

__END__

=head1 NAME 

Plack::Middleware::Timeout

=head1 SYNOPSIS

    my $app = sub { ... };

    Plack::Middleeare::Timeout->wrap(
        $app,
        timeout  => sub { ... } || 60,
        # optional callback to set the custom response 
        response => sub {
            my ($response_obj,$execution_time) = @_;

            $response_obj->code(HTTP_REQUEST_TIMEOUT);
            $response_obj->body( encode_json({
                timeout => 1,
                other_info => {...},
            }));

            return $plack_response;
        }
    );

=head1 DESCRIPTION

Timeout any plack requests at an arbitrary time.

=head1 PARAMETERS

=over

=item timeout

Determines how we're going to get the timeout value, either subref returning a value or any value accepted by subroutine defined in Time::HiRes::alarm, default 120 seconds.

=item response

Optional subroutine that receives two parameters, a Plack::Response object that we can further modify 
to fit our needs, if none is provided the middleware resolves to emitting a warning:

=over

'Terminated request for uri '%s' due to timeout (%ds)'

=back

=back

=head1 AUTHOR

Tomasz Czepiel <tjmc@cpan.org>

=head1 LICENCE 

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

