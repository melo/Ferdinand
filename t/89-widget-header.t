#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Ferdinand::Widgets::Header;
use Ferdinand::Context;

my $ctx = Ferdinand::Context->new(
  map    => bless({}, 'Ferdinand::Map'),
  action => bless({}, 'Ferdinand::Action'),
);

subtest 'Scalar header' => sub {
  $ctx->clear_buffer;

  my $t = Ferdinand::Widgets::Header->setup({header => 'my'});
  isa_ok($t, 'Ferdinand::Widgets::Header', 'Class name for widget object');

  $t->render($ctx);
  cmp_deeply($ctx->buffer, '<h1>my</h1>', 'Header as expected');
};

subtest 'CodeRef header' => sub {
  $ctx->clear_buffer;
  my $cl = $ctx->clone(params => {type => 'user'});

  my $cb = sub { ucfirst($_[1]->params->{type}) };
  my $t = Ferdinand::Widgets::Header->setup({header => $cb});
  isa_ok($t, 'Ferdinand::Widgets::Header', 'Class name for widget object');

  $t->render($cl);
  cmp_deeply($cl->buffer, '<h1>User</h1>', 'Header as expected');
};


done_testing();
