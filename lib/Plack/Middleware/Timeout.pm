package Plack::Middleware::Timeout;

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(timeout);
use Plack::Request;
use Plack::Response;
use Scope::Guard ();

our $VERSION = '0.01';

sub call {
    my ( $self, $env ) = @_;

    my $alarm_msg = 'Plack::Middleware::Timeout';
    local $SIG{ALRM} = sub { die $alarm_msg };

    my $time_started = 0;
    eval {

        $time_started = time();
        alarm( $self->timeout || 120 );
        my $guard = Scope::Guard->new(
            sub {
                alarm 0;
            }
        );

        return $self->app->($env);

    } or do {
        my $request        = Plack::Request->new($env);
        my $execution_time = time() - $time_started;
        warn
          sprintf
          "Terminated request for uri '%s' - took %d seconds (timeout %ds)",
          $request->request_uri,
          $execution_time,
          $self->timeout;

        return Plack::Response->new(408)->finalize;
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
        timeout => 60,
    );

=head1 DESCRIPTION

Timeout any plack requests at an arbitrary time.

=head1 AUTHOR

Tomasz Czepiel 

=head1 LICENCE 

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

