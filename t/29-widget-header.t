#!perl

use strict;
use warnings;
use Ferdinand::Tests;


subtest 'Scalar header' => sub {
  my $t = setup_widget('Header', {header => 'my'});
  isa_ok($t, 'Ferdinand::Widgets::Header', 'Class name for widget object');

  my $ctx = render_ok($t);
  cmp_deeply($ctx->buffer, '<h1>my</h1>', 'Header as expected');
};


subtest 'CodeRef header' => sub {
  my $cb = sub { ucfirst($_[1]->params->{type}) };
  my $t = setup_widget('Header', {header => $cb});
  isa_ok($t, 'Ferdinand::Widgets::Header', 'Class name for widget object');

  my $ctx = render_ok($t, {params => {type => 'user'}});
  cmp_deeply($ctx->buffer, '<h1>User</h1>', 'Header as expected');
};


done_testing();
