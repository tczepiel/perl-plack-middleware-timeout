use strict;
use warnings;

use Plack::Middleware::Timeout;
use Test::More tests => 3;
use Plack::Test;
use HTTP::Request::Common;

my $app = sub { return [ 200, [], ["Hello "] ] };
my $timeout_app = sub { sleep 5; return [ 200, [], "Hello" ] };

$app = Plack::Middleware::Timeout->wrap( $app, timeout => 2 );

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/" );
    is $res->code, 200, "response looks ok";
};

$timeout_app = Plack::Middleware::Timeout->wrap(
    $timeout_app,
    timeout  => 2,
    response => sub {
        my $plack_response = shift;
        $plack_response->body('the request timed out');
        return $plack_response;
    },
);

test_psgi $timeout_app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/" );
    is $res->code, 408, "response code ok";
    is $res->content, "the request timed out", 'response body looks ok';
};
