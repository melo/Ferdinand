#!perl

use strict;
use warnings;
use Ferdinand::Tests;


my $cb = setup_widget(
  'CB',
  { cb => sub {
      my ($self) = @_;
      my $p = $_->params;

      $_->stash(xpto => $p->{xpto}, wg => $self);
    },
  }
);
isa_ok($cb, 'Ferdinand::Widgets::CB', 'Class name for widget object ok');

my $ctx = render_ok($cb, {params => {xpto => 'xpto'}});
is($ctx->stash->{xpto}, 'xpto', "Stash key 'xpto' as expected");
is($ctx->stash->{wg},   $cb,    "Stash key 'wg' as expected");


done_testing();
