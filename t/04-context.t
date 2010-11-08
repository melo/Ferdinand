#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use Ferdinand::Context;

my $ctx;
is(
  exception {
    $ctx = Ferdinand::Context->new(
      impl   => bless({}, 'Ferdinand::Impl'),
      action => bless({}, 'Ferdinand::Action'),
      fields => {a => 1, b => 2},
    );
  },
  undef,
  'Created context and lived'
);


isa_ok($ctx->impl,   'Ferdinand::Impl');
isa_ok($ctx->action, 'Ferdinand::Action');
is($ctx->widget, undef, 'Widget is undef');


subtest 'context cloning' => sub {
  my $new = $ctx->clone(a => undef, c => 3);
  isnt($ctx, $new, 'Clone returns a new object');
  isa_ok($new, 'Ferdinand::Context');

  cmp_deeply($new->fields, {b => 2, c => 3}, 'Cloning replaces fields');
};


subtest 'context fields' => sub {
  cmp_deeply($ctx->fields, {a => 1, b => 2}, 'Fields as expected');

  my $f = $ctx->fields(b => undef, c => 3);
  is($f, $ctx->fields, 'fields() returs the hashref');
  cmp_deeply($f, {a => 1, c => 3}, 'Fields modified as expected');
};


subtest 'context stash' => sub {
  cmp_deeply($ctx->stash, {}, 'Stash is empty');

  my $s = $ctx->stash(b => undef, c => 3);
  is($s, $ctx->stash, 'stash() returs the hashref');
  cmp_deeply($s, {c => 3}, 'Stash modified as expected');
  $ctx->stash(c => undef, d => 4);
  cmp_deeply($s, {d => 4}, 'Stash modified as expected');
};


done_testing();
