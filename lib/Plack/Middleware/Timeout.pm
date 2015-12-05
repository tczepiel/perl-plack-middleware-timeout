package Plack::Middleware::Timeout;

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(timeout response soft_timeout on_soft_timeout);
use Plack::Request;
use Plack::Response;
use Scope::Guard ();
use Time::HiRes qw(alarm time);

our $VERSION = '0.07';

sub _get_alarm_subref {
    my $self = shift;

   my $timeout = $self->timeout || 120;
   return ref($timeout) eq 'CODE' ? $timeout : sub { alarm($timeout) };
}

my $default_on_soft_timeout = sub {
    warn sprintf "Soft timeout reached for uri '%s' (soft timeout: %ds) request took %ds", @_;
};

sub call {
    my ( $self, $env ) = @_;

    my $alarm_msg = 'Plack::Middleware::Timeout';
    local $SIG{ALRM} = sub { die $alarm_msg };

    my $time_started = 0;
    local $@;
    eval {

        $time_started = time();
        $self->_get_alarm_subref->();

        my $guard = Scope::Guard->new(sub {
            alarm 0;
        });

        my $soft_timeout_guard;

        if ( my $soft_timeout = $self->soft_timeout ) {
            $soft_timeout_guard = Scope::Guard->new(
                sub {
                    if ( time() - $time_started > $soft_timeout ) {
                        my $on_soft_timeout =
                          $self->on_soft_timeout || $default_on_soft_timeout;

                        my $request = Plack::Request->new($env);

                        $on_soft_timeout->(
                            $request->uri,
                            $soft_timeout,
                            $execution_time,
                        );
                    }
                }
            );
        }

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
              $request->uri,
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

=item soft_timeout

Same as timeout, except this value will be checked after the call to the app has completed. See also C<on_soft_timeout> below.

=item on_soft_timeout

optional coderef that'll get executed when we established, that time required to serve the response was longer than a value provided in the soft_timeout parameter. If soft_timeout is set but no on_soft_timeout coderef is provided, we're going to issue a warning as follows; the response will be returned as normal.

=over

'Soft timeout reached for uri '%s' (soft timeout: %ds) request took %ds'

=back

=back

=head1 AUTHOR

Tomasz Czepiel <tjmc@cpan.org>

=head1 LICENCE 

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

