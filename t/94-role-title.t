#!perl

package X1;
BEGIN { $INC{'X1.pm'}++ }

use Ferdinand::Setup 'class';
with 'Ferdinand::Roles::Title', 'Ferdinand::Roles::Setup';


package main;

use strict;
use warnings;
use Ferdinand::Tests;


my $ctx = build_ctx(stash => {type => 'Magic'});

my $x = setup_widget('+X1', {title => 'xpto'});
is($x->title($ctx), 'xpto', '... title is ok (scalar)');

$x = setup_widget('+X1', {title => sub { $_->stash->{type} },});
is($x->title($ctx), 'Magic', '... title is ok (cb)');


done_testing();
