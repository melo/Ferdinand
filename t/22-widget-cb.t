#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Ferdinand::Widgets::CB;
use Ferdinand::Context;

my $ctx = Ferdinand::Context->new(
  map    => bless({}, 'Ferdinand::Map'),
  action => bless({}, 'Ferdinand::Action'),
  params => {xpto => 'xpto'},
);

my $c = Ferdinand::Widgets::CB->setup(
  { cb => sub {
      my ($self) = @_;
      my $p = $_->params;

      $_->stash(xpto => $p->{xpto}, wg => $self);
      }
  }
);
isa_ok($c, 'Ferdinand::Widgets::CB', 'Class name for widget object ok');

$c->render($ctx);
is($ctx->stash->{xpto}, 'xpto', "Stash key 'xpto' as expected");
is($ctx->stash->{wg},   $c,     "Stash key 'wg' as expected");


done_testing();
