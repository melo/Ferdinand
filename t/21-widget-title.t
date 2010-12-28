#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::Widgets::Title;

my $ctx = Ferdinand::Context->new(
  map    => bless({}, 'Ferdinand::Map'),
  action => bless({}, 'Ferdinand::Action'),
);

subtest 'Scalar title' => sub {
  $ctx->clear_buffer;

  my $t = Ferdinand::Widgets::Title->setup({title => 'my'});
  isa_ok($t, 'Ferdinand::Widgets::Title', 'Class name for widget object');

  $t->render($ctx);
  cmp_deeply($ctx->stash, {title => 'my'}, 'Title as expected');
};

subtest 'CodeRef title' => sub {
  my $cl = $ctx->clone(params => {title => 'user'});

  my $cb = sub { ucfirst($_[1]->params->{title}) };
  my $t = Ferdinand::Widgets::Title->setup({title => $cb});
  isa_ok($t, 'Ferdinand::Widgets::Title', 'Class name for widget object');

  $t->render($cl);
  cmp_deeply($cl->stash, {title => 'User'}, 'Title as expected');
};


done_testing();
