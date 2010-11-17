#!perl

package X1;

use Ferdinand::Setup 'class';
use Method::Signatures;
with 'Ferdinand::Roles::Renderer';

method render_end ($ctx) {
  my $b = $ctx->buffer;
  $ctx->clear_buffer;
  $ctx->buffer(uc($b))
}


package X2;

use Ferdinand::Setup 'class';
use Method::Signatures;
extends 'X1';

method render_self ($ctx) {
  $ctx->buffer(' more!');
}


package main;

use strict;
use warnings;
use Test::More;
use Ferdinand::Context;

my $ctx = Ferdinand::Context->new(
  map    => bless({}, 'Ferdinand::Map'),
  action => bless({}, 'Ferdinand::Action'),
  buffer => 'aaaa',
);

X1->new->render($ctx);
is($ctx->buffer, 'AAAA', 'Got the expected rendered value X1');

X2->new->render($ctx);
is($ctx->buffer, 'AAAA MORE!', 'Got the expected rendered value X2');


done_testing();
