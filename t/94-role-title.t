#!perl

package X1;
BEGIN { $INC{'X1.pm'}++ }

use Ferdinand::Setup 'class';
with 'Ferdinand::Roles::Title', 'Ferdinand::Roles::Setup';


package main;

use strict;
use warnings;
use Ferdinand::Tests;


my $ctx = build_ctx(
  stash => {type => 'Magic'},
  item => bless({make => 'snow'}, 'X1')
);

my $x = setup_widget('+X1', {title => 'xpto'});
is($x->title($ctx), 'xpto', '... title is ok (scalar)');
is(
  $x->render_title($ctx),
  '<h1 class="w_title">xpto</h1>',
  '... html version ok'
);

$x = setup_widget(
  '+X1',
  { title => sub { $_->stash->{type} }
  }
);
is($x->title($ctx), 'Magic', '... title is ok (cb + ctx)');
is(
  $x->render_title($ctx),
  '<h1 class="w_title">Magic</h1>',
  '... html version ok'
);

$x = setup_widget(
  '+X1',
  { title => sub { shift->{make} }
  }
);
is($x->title($ctx), 'snow', '... title is ok (cb + item)');
is(
  $x->render_title($ctx, {class => "xpto"}),
  '<h1 class="xpto">snow</h1>',
  '... html version ok'
);

$x = setup_widget(
  '+X1',
  { title => sub { shift->{make} }
  }
);
is($x->title($ctx), 'snow', '... title is ok (cb + item)');
is(
  $x->render_title($ctx),
  '<h1 class="w_title">snow</h1>',
  '... html version ok'
);


done_testing();
