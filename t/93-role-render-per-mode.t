#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use TestRenderMode;

my $w = TestRenderMode->new(id => 1);
my $ctx;

$ctx = render_ok($w);
is($ctx->buffer, 'reader', 'default mode => reader ok');

$ctx = render_ok($w, {mode => 'view'});
is($ctx->buffer, 'reader', 'mode view => reader ok');

$ctx = render_ok($w, {mode => 'list'});
is($ctx->buffer, 'reader', 'mode list => reader ok');

$ctx = render_ok($w, {mode => 'create'});
is($ctx->buffer, 'writer', 'mode create => writer ok');

$ctx = render_ok($w, {mode => 'create_do'});
is($ctx->buffer, 'writer', 'mode create_do => writer ok');

$ctx = render_ok($w, {mode => 'edit'});
is($ctx->buffer, 'writer', 'mode edit => writer ok');

$ctx = render_ok($w, {mode => 'edit_do'});
is($ctx->buffer, 'writer', 'mode edit_do => writer ok');

$ctx = render_ok($w, {mode => 'no_such_mode'});
is($ctx->buffer, '', 'mode unknown, no method called');


done_testing();
