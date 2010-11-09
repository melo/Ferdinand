#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use Ferdinand::Context;
use Ferdinand::Action;

my $ferdinand = bless {}, 'Ferdinand';
my $action    = bless {}, 'Ferdinand::Action';

my $ctx;
is(
  exception {
    $ctx = Ferdinand::Context->new(
      ferdinand  => $ferdinand,
      action     => $action,
      uri_helper => sub { join(' ', @_) },
      params     => {a => 1, b => 2},
      stash      => {x => 9, y => 8},
    );
  },
  undef,
  'Created context and lived'
);

isa_ok($ctx->ferdinand, 'Ferdinand');
isa_ok($ctx->action,    'Ferdinand::Action');

is($ctx->widget, undef,    'Widget is undef');
is($ctx->uri(5), "$ctx 5", 'uri_helper works');

cmp_deeply($ctx->params, {a => 1, b => 2}, 'param as expected');
cmp_deeply($ctx->stash,  {x => 9, y => 8}, 'stash as expected');


subtest 'context cloning' => sub {
  is($ctx->parent, undef, 'parent is undef');
  $ctx->buffer('a1');
  is($ctx->buffer, 'a1', 'Buffer has something in it');

  is($ctx->item, undef, 'Item is undef by default');
  is($ctx->set,  undef, 'Set is undef by default');

  subtest 'test cloned context' => sub {
    my $c1 = $ctx->clone;
    isnt($ctx, $c1, 'Clone returns a new object');
    is($c1->parent, $ctx, "... parent is old context");
    isa_ok($c1, 'Ferdinand::Context');

    cmp_deeply($c1->params, {a => 1, b => 2}, 'cloned param as expected');
    cmp_deeply($c1->stash,  {x => 9, y => 8}, 'cloned stash as expected');

    for my $attr (qw( ferdinand action widget uri_helper )) {
      is($c1->$attr, $ctx->$attr, "Cloned context '$attr' is the same");
    }

    $c1->item({a => 1, b => 2});
    $c1->set([{a => 1}, {a => 2}]);
    cmp_deeply($c1->item, {a => 1, b => 2}, 'Item set as expected');
    cmp_deeply($c1->set, [{a => 1}, {a => 2}], 'Set updated as expected');

    is($c1->buffer, '', 'Cloned context buffer is empty');
    $c1->buffer('a2');
    is($c1->buffer, 'a2', '... buffer updated properly');

    is($c1->parent->buffer, 'a1', 'Parent ctx still has the original buffer');
  };

  is($ctx->buffer, 'a1a2', 'Cloned context updated');

  is($ctx->item, undef, 'Item is undef again');
  is($ctx->set,  undef, 'Set is undef again');
};


subtest 'context stash' => sub {
  cmp_deeply($ctx->stash, {x => 9, y => 8}, 'Stash as expected');

  my $s = $ctx->stash(b => undef, c => 3);
  is($s, $ctx->stash, 'stash() returs the hashref');
  cmp_deeply($s, {c => 3, x => 9, y => 8}, 'Stash modified as expected');
  $ctx->stash(c => undef, d => 4);
  cmp_deeply($s, {d => 4, x => 9, y => 8}, 'Stash modified as expected');
};


subtest 'buffer management' => sub {
  my $c1 = Ferdinand::Context->new(
    ferdinand => $ferdinand,
    action    => $action,
  );

  is($c1->buffer, '', 'Buffer is empty from the start');

  $c1->buffer('a', 'b', 'c');
  is($c1->buffer, 'abc', '... and now its no longer empty');

  $c1->buffer('A', 'B', 'C');
  is($c1->buffer, 'abcABC', '... concat works');

  $c1->clear_buffer;
  is($c1->buffer, '', 'Buffer is empty again');
};


subtest 'render_field output' => sub {
  my $c1 = Ferdinand::Context->new(
    ferdinand => $ferdinand,
    action    => $action,
  );

  my %args = (
    item  => {v => '<abcd & efgh>', e => '!!'},
    field => 'v',
    meta  => {},
  );

  is($c1->render_field(%args), '&lt;abcd &amp; efgh&gt;', 'Single row value');

  $args{meta}{formatter} = sub { return uc($_) };
  is(
    $c1->render_field(%args),
    '&lt;ABCD &amp; EFGH&gt;',
    'Single row value, with formatter'
  );

  $args{meta}{link_to} = sub { $_->{e} };
  is(
    $c1->render_field(%args),
    '<a href="!!">&lt;ABCD &amp; EFGH&gt;</a>',
    'link_to value'
  );

  $args{meta}{linked} = ['view', 'me'];
  is($c1->render_field(%args), '&lt;ABCD &amp; EFGH&gt;', 'linked value');

  $c1 = $c1->clone(uri_helper => sub { return join('/', @{$_[1]}) });
  is(
    $c1->render_field(%args),
    '<a href="view/me">&lt;ABCD &amp; EFGH&gt;</a>',
    'link_to value, with formatter'
  );
};


done_testing();
