#!perl

package X;

use Ferdinand::Setup 'class';
use Method::Signatures;
with 'Ferdinand::Roles::Setup';

has 'str' => (isa => 'Str', is => 'ro');
has 'end' => (isa => 'Str', is => 'rw');

after setup_attrs => method ($class:, $attrs, $meta, $sys, $stash) {
  $attrs->{str} = delete $meta->{str} if exists $meta->{str};
  $meta->{sys}  = $sys;
  $stash->{end} = 'called';
};

method setup_done ($stash) {
  $self->end($stash->{end});
}


package main;

use strict;
use warnings;
use Ferdinand::Tests;

my $m = {str => 'aa', ypt => 'bb'};
my $x = X->setup($m);

ok($x, 'Got something');
isa_ok($x, 'X', '... of the expected class X');

is($x->str, 'aa', "Attribute 'str' is 'aa'");
cmp_deeply($m, {ypt => 'bb', sys => 'X'}, "Final meta hashref as expected");

is($x->end, 'called', 'setup_done() called properly');

done_testing();
