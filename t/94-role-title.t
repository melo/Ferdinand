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

$x = setup_widget('+X1', {title => sub { $_->stash->{type} },});
is($x->title($ctx), 'Magic', '... title is ok (cb + ctx)');

$x = setup_widget('+X1', {title => sub { shift->{make} },});
is($x->title($ctx), 'snow', '... title is ok (cb + item)');


done_testing();
