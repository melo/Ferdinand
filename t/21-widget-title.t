#!perl

use strict;
use warnings;
use Ferdinand::Tests;


subtest 'Scalar title' => sub {
  my $t = setup_widget('Title', {title => 'my'});
  isa_ok($t, 'Ferdinand::Widgets::Title', 'Class name for widget object');

  my $ctx = render_ok($t);
  cmp_deeply($ctx->stash, {title => 'my'}, 'Title as expected');
};


subtest 'CodeRef title (using context)' => sub {
  my $cb = sub { ucfirst($_->params->{title}) };
  my $t = setup_widget('Title', {title => $cb});
  isa_ok($t, 'Ferdinand::Widgets::Title', 'Class name for widget object');

  my $ctx = render_ok($t, {params => {title => 'user'}});
  cmp_deeply($ctx->stash, {title => 'User'}, 'Title as expected');
};


subtest 'CodeRef title (using item)' => sub {
  my $cb = sub { ucfirst(shift->{title}) };
  my $t = setup_widget('Title', {title => $cb});
  isa_ok($t, 'Ferdinand::Widgets::Title', 'Class name for widget object');

  my $ctx = render_ok($t, {item => bless({title => 'user'}, 'X')});
  cmp_deeply($ctx->stash, {title => 'User'}, 'Title as expected');
};


done_testing();
