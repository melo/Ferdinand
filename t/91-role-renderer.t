#!perl

package X1;

use Ferdinand::Setup 'class';
use Method::Signatures;
with 'Ferdinand::Roles::Renderer';

method render_end($ctx) {
  my $b = $ctx->clear_buffer;
  $ctx->buffer(uc($b));

  my $s = $ctx->stash;
  $s->{hitted} = $s->{hit_me}++;
}


package X2;

use Ferdinand::Setup 'class';
use Method::Signatures;
extends 'X1';

method render_begin($ctx) {
  $ctx->overlay(stash => {});
}

method render_self($ctx) {
  $ctx->buffer(' more!');

  my $s = $ctx->stash;
  $s->{hitted} = $s->{hit_me}++;
}


package main;

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Ferdinand::Context;

my $ctx = Ferdinand::Context->new(
  map    => bless({}, 'Ferdinand::Map'),
  action => bless({}, 'Ferdinand::Action'),
  buffer => 'aaaa',
  stash => {hit_me => 5},
);


cmp_deeply($ctx->stash, {hit_me => 5}, 'Stash before X1 ok');
X1->new->render($ctx);
is($ctx->buffer, 'AAAA', 'Got the expected rendered value X1');
cmp_deeply($ctx->stash, {hit_me => 6, hitted => 5}, 'Stash hit after X1');


X2->new->render($ctx);
is($ctx->buffer, 'AAAA MORE!', 'Got the expected rendered value X2');
cmp_deeply($ctx->stash, {hit_me => 6, hitted => 5}, 'Stash as before X2');


done_testing();
