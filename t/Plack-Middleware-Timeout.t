use strict;
use warnings;

use Plack::Middleware::Timeout;
use Test::More qw(no_plan);
use Plack::Test;
use HTTP::Request::Common;
use Data::Dumper;

my $app = sub { return [ 200, [], [ "Hello "] ] };
my $timeout_app = sub { sleep 5; return [ 200, [], "Hello" ] };

$app =  Plack::Middleware::Timeout->wrap(
        $app,
        timeout => 2,
);

test_psgi $app, sub {
      my $cb  = shift;
      my $res = $cb->(GET "/");
      is $res->code, 200, "response looks ok"
    };

$timeout_app = Plack::Middleware::Timeout->wrap(
        $timeout_app,
        timeout => 2,
);

test_psgi $timeout_app, sub {
      my $cb  = shift;
      my $res = $cb->(GET "/");
      is $res->code, 408, "request looks ok";
};
