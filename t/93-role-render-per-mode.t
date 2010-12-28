#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use TestRenderMode;

my $w = TestRenderMode->new(id => 1);

my $ctx = build_ctx();
$w->render($ctx);
is($ctx->buffer, 'reader', 'default mode => reader ok');

$ctx = build_ctx(mode => 'view');
$w->render($ctx);
is($ctx->buffer, 'reader', 'mode view => reader ok');

$ctx = build_ctx(mode => 'list');
$w->render($ctx);
is($ctx->buffer, 'reader', 'mode list => reader ok');

$ctx = build_ctx(mode => 'create');
$w->render($ctx);
is($ctx->buffer, 'writer', 'mode create => writer ok');

$ctx = build_ctx(mode => 'create_do');
$w->render($ctx);
is($ctx->buffer, 'writer', 'mode create_do => writer ok');

$ctx = build_ctx(mode => 'no_such_mode');
is(exception { $w->render($ctx) }, undef, "Unknown mode doesn't kill you");
is($ctx->buffer, '', 'mode unknown, no method called');

done_testing();
