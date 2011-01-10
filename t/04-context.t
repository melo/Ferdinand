#!perl

use strict;
use warnings;
use Ferdinand;
use Ferdinand::Tests;
use Ferdinand::Action;
use Test::MockObject;

sub _ctx {
  my @extra_args = @_;

  my $ctx;
  my $map    = bless {}, 'Ferdinand::Map';
  my $action = bless {}, 'Ferdinand::Action';

  is(
    exception {
      $ctx = Ferdinand->build_ctx(
        { map        => $map,
          action     => $action,
          action_uri => URI->new('http://example.com/something'),
          @extra_args,
        }
      );
    },
    undef,
    'Context created, no exceptions'
  );

  return $ctx;
}

sub _ctx_full {
  return _ctx(
    params => {a => 1, b => 2},
    stash  => {x => 9, y => 8},
    @_,
  );
}


subtest 'Basic tests' => sub {
  my $c1 = _ctx_full(params => {a => 1, b => 2, 'c.a[1].b' => 'taxi'});

  isa_ok($c1->map,        'Ferdinand::Map');
  isa_ok($c1->action,     'Ferdinand::Action');
  isa_ok($c1->action_uri, 'URI');

  is($c1->widget, undef, 'Widget is undef');

  is($c1->action_uri->path, '/something', 'action_uri works');

  cmp_deeply(
    $c1->params,
    {a => 1, b => 2, c => {a => [undef, {b => 'taxi'}]}},
    'param as expected'
  );
  cmp_deeply($c1->stash, {x => 9, y => 8}, 'stash as expected');

  is($c1->mode, 'view', 'mode as expected');

  is($c1->prefix, '', 'prefix default as expected');

  $c1->prefix('z');
  is($c1->prefix, 'z', 'prefix as expected');
};


subtest 'context cloning' => sub {
  my $c1 = _ctx_full();

  is($c1->parent, undef, 'parent is undef');
  $c1->buffer('a1');
  is($c1->buffer, 'a1', 'Buffer has something in it');

  is($c1->item, undef, 'Item is undef by default');
  is($c1->set,  undef, 'Set is undef by default');

  subtest 'test cloned context' => sub {
    my $c2 = $c1->clone;
    isnt($c1, $c2, 'Clone returns a new object');
    is($c2->parent, $c1, "... parent is old context");
    isa_ok($c2, 'Ferdinand::Context');

    cmp_deeply($c2->params, {a => 1, b => 2}, 'cloned param as expected');
    cmp_deeply($c2->stash,  {x => 9, y => 8}, 'cloned stash as expected');

    for my $attr (qw( map action widget uri_helper )) {
      is($c2->$attr, $c1->$attr, "Cloned context '$attr' is the same");
    }

    $c2->item(bless({a => 1, b => 2}, 'X'));
    $c2->set(bless([{a => 1}, {a => 2}], 'X'));
    cmp_deeply(
      $c2->item,
      bless({a => 1, b => 2}, 'X'),
      'Item set as expected'
    );
    cmp_deeply(
      $c2->set,
      bless([{a => 1}, {a => 2}], 'X'),
      'Set updated as expected'
    );

    is($c2->buffer, '', 'Cloned context buffer is empty');
    $c2->buffer('a2');
    is($c2->buffer, 'a2', '... buffer updated properly');

    is($c2->parent->buffer, 'a1', 'Parent ctx still has the original buffer');
  };

  subtest 'test cloned with args' => sub {
    my $c2 = $c1->clone(params => {p1 => 1, p2 => 2});

    cmp_deeply(
      $c2->params,
      {p1 => 1, p2 => 2},
      'cloned params with new values'
    );
    cmp_deeply($c2->stash, {x => 9, y => 8}, 'cloned stash as previous');
  };

  is($c1->buffer, 'a1a2', 'Cloned context updated');

  is($c1->item, undef, 'Item is undef again');
  is($c1->set,  undef, 'Set is undef again');

  cmp_deeply($c1->params, {a => 1, b => 2}, 'params still as expected');
};


subtest 'context overlay' => sub {
  my $c1 = _ctx_full();

  is($c1->parent, undef, 'parent is undef');
  $c1->buffer('a1');
  is($c1->buffer, 'a1', 'Buffer has something in it');

  is($c1->item, undef, 'Item is undef by default');
  is($c1->set,  undef, 'Set is undef by default');

  cmp_deeply($c1->params, {a => 1, b => 2}, 'base param as expected');
  cmp_deeply($c1->stash,  {x => 9, y => 8}, 'base stash as expected');

  subtest 'test overlay context' => sub {
    my $g =
      $c1->overlay(set => bless([{a => 1}, {a => 2}], 'X'), stash => {});

    cmp_deeply(
      $c1->set,
      bless([{a => 1}, {a => 2}], 'X'),
      'Set with new value from overlay'
    );

    cmp_deeply($c1->params, {a => 1, b => 2}, 'overlay param as expected');
    cmp_deeply($c1->stash, {}, 'overlay stash as expected');

    is($c1->buffer, 'a1', 'Overlayed buffer is the same');
    $c1->buffer('a2');
    $c1->item(bless({a => 1, b => 2}, 'X'));
  };

  is($c1->buffer, 'a1a2', 'Buffer as expected after overlay cleanup');

  cmp_deeply(
    $c1->item,
    bless({a => 1, b => 2}, 'X'),
    'Item as expected after overlay cleanup'
  );
  cmp_deeply($c1->stash, {x => 9, y => 8}, 'Stash back to pre-overlay value');
  is($c1->set, undef, 'Set back to pre-overlay value');
};


subtest 'context stash' => sub {
  my $c1 = _ctx_full();

  cmp_deeply($c1->stash, {x => 9, y => 8}, 'Stash as expected');

  my $s = $c1->stash(b => undef, c => 3);
  is($s, $c1->stash, 'stash() returs the hashref');
  cmp_deeply($s, {c => 3, x => 9, y => 8}, 'Stash modified as expected');
  $c1->stash(c => undef, d => 4);
  cmp_deeply($s, {d => 4, x => 9, y => 8}, 'Stash modified as expected');
};


subtest 'buffer management' => sub {
  my $c1 = _ctx();

  is($c1->buffer, '', 'Buffer is empty from the start');

  $c1->buffer('a', 'b', 'c');
  is($c1->buffer, 'abc', '... and now its no longer empty');

  $c1->buffer('A', 'B', 'C');
  is($c1->buffer, 'abcABC', '... concat works');

  my $b = $c1->clear_buffer;
  is($c1->buffer, '',       'Buffer is empty again');
  is($b,          'abcABC', '... and the old buffer is returned');
};


subtest 'buffer stack', sub {
  my $c1 = _ctx();

  is($c1->buffer, '', 'Buffer empty at the start');

  $c1->buffer('aa');
  is($c1->buffer, 'aa', 'Buffer modification ok');

  $c1->buffer_stack;
  is($c1->buffer, '', 'Buffer is empty once more');

  $c1->buffer('bb');
  $c1->buffer_merge;
  is($c1->buffer, 'aabb', 'Buffer merging ok');

  $c1->buffer_stack('cc');
  is($c1->buffer, 'cc', 'Buffer with proper value');

  $c1->buffer_stack('dd');
  is($c1->buffer, 'dd', 'Buffer with proper value again');

  $c1->buffer_merge('111');
  $c1->buffer_merge;
  is($c1->buffer, 'aabbccdd111', 'Buffer ok');
};


subtest 'buffer wrap', sub {
  my $c1 = _ctx();

  is($c1->buffer,       '',   'Buffer empty at the start');
  is($c1->buffer('aa'), 'aa', 'Buffer not empty');

  $c1->buffer_wrap('pp');
  is($c1->buffer, 'ppaa', 'Buffer with prepended stuff');

  $c1->buffer_wrap(undef, 'pp');
  is($c1->buffer, 'ppaapp', 'Buffer with appended stuff');

  $c1->buffer_wrap('<p>', '</p>');
  is($c1->buffer, '<p>ppaapp</p>', 'Buffer wrapped');
};


subtest 'buffers and parentage', sub {
  my $c1 = _ctx();
  my $c2 = _ctx(parent => $c1);
  my $c3 = _ctx(parent => $c1);

  $c1->buffer('aa');
  $c2->buffer('bb');
  $c3->buffer('0');

  undef $c2;
  is($c1->buffer, 'aabb', 'Buffer after parent merge ok I');

  undef $c3;
  is($c1->buffer, 'aabb0', 'Buffer after parent merge ok II');

  is(exception { undef $c1 }, undef, 'No parent, no die');
};


subtest 'error mgmt', sub {
  my $c1 = _ctx();

  ok(!$c1->has_errors, 'No errors on new contexts');
  cmp_deeply([$c1->errors], [], '... so empty kv for errors');
  is($c1->error_for('x'), undef, 'No error for x field');

  $c1->add_error(x => 42);
  ok($c1->has_errors, 'Found errors in context');
  is($c1->error_for('x'), 42, '... found error for x field');
  cmp_deeply([$c1->errors], [[x => 42]], '... kv has proper errors');

  $c1->add_error(x => 84);
  ok($c1->has_errors, 'Found errors in context');
  is($c1->error_for('x'), 84, '... found error for x field');
  cmp_deeply([$c1->errors], [[x => 84]], '... kv has proper errors');

  $c1->clear_errors;
  ok(!$c1->has_errors, 'No errors after clear_errors()');
};


done_testing();

sub like_all {
  my $prefix = shift;
  my $text   = shift;

  ### Make sure Test::Builder reports errors in the proper place
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  ok($text, "Got $prefix");
  for my $re (@_) {
    like($text, $re, "... matches $re");
  }
}
