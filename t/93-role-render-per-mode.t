#!perl

use strict;
use warnings;
use Test::More;
use lib 't/tlib';
use TestRenderMode;
use Ferdinand::Context;

my $w = TestRenderMode->new(id => 1);

my $ctx = _ctx();
$w->render($ctx);
is($ctx->buffer, 'reader', 'Got the reader part ok view');

$ctx = _ctx(mode => 'create');
$w->render($ctx);
is($ctx->buffer, 'writer', 'Got the writer part ok create');

$ctx = _ctx(mode => 'create_ok');
$w->render($ctx);
is($ctx->buffer, 'writer', 'Got the writer part ok for mode create_ok');


done_testing();

sub _ctx {
  return Ferdinand::Context->new(
    map    => bless({}, 'Ferdinand::Map'),
    action => bless({}, 'Ferdinand::Action'),
    @_,
  );
}
