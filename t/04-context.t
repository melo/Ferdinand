#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use Ferdinand::Context;
use Ferdinand::Action;

my $impl = bless {}, 'Ferdinand::Impl';

my $ctx;
is(
  exception {
    $ctx = Ferdinand::Context->new(
      impl        => $impl,
      action      => bless({}, 'Ferdinand::Action'),
      action_name => 'view',
      fields      => {a => 1, b => 2},
    );
  },
  undef,
  'Created context and lived'
);


isa_ok($ctx->impl,   'Ferdinand::Impl');
isa_ok($ctx->action, 'Ferdinand::Action');
is($ctx->action_name, 'view', 'action_name as expected');
is($ctx->widget,      undef,  'Widget is undef');


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


subtest 'field shortcuts' => sub {
  my $c1 = Ferdinand::Context->new(
    impl        => $impl,
    action      => Ferdinand::Action->new(title => 'my title'),
    action_name => 'view',
  );
  is($c1->row,  undef, 'row() is undef');
  is($c1->rows, undef, 'rows() is undef');

  $c1->fields(row => 1, rows => 2);
  is($c1->row,  1, 'row() as expected');
  is($c1->rows, 2, 'rows() as expected');

  is($c1->params, undef, 'Field params is undef by default');
  $c1->fields(params => {x => 1, y => 2});
  cmp_deeply($c1->params, {x => 1, y => 2}, '... and now it has something');

  is($c1->id, undef, 'Field id is undef by default');
  $c1->fields(id => 42);
  is($c1->id, 42, '... and now it has the expected value');

  is($c1->uri_helper, undef, 'Field uri_helper is undef by default');
  $c1->fields(uri_helper => sub { join(' ', @_) });
  is($c1->uri_helper(5), "$c1 5",
    '... and now it has the expected behaviour');
};


subtest 'page title' => sub {
  my $c1 = Ferdinand::Context->new(
    impl        => $impl,
    action      => Ferdinand::Action->new(title => 'my title'),
    action_name => 'view',
  );
  is($c1->page_title, 'my title', 'Text-based page title');

  my $c2 = Ferdinand::Context->new(
    impl        => $impl,
    action      => Ferdinand::Action->new(title => sub {'dyn title'}),
    action_name => 'view',
  );
  is($c2->page_title, 'dyn title', 'CodeRef-based page title');

  my $c3 = Ferdinand::Context->new(
    impl   => $impl,
    action => Ferdinand::Action->new(
      title => sub { join(' ', 'dyn title for', @_[1 .. $#_]) }
    ),
    action_name => 'view',
  );
  is(
    $c3->page_title('x', 'y'),
    'dyn title for x y',
    'CodeRef-based page title with args',
  );
};


done_testing();
