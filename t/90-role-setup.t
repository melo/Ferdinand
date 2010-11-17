#!perl

package X;

use Ferdinand::Setup 'class';
use Method::Signatures;
with 'Ferdinand::Roles::Setup';

has 'str' => (isa => 'Str', is => 'ro');

method setup_attrs ($class:, $attrs, $meta, $sys) {
  $attrs->{str} = delete $meta->{str} if exists $meta->{str};
  $meta->{sys} = $sys;
}


package main;

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Scalar::Util 'blessed';

my $m = {str => 'aa', ypt => 'bb'};
my $x = X->setup($m);

ok(blessed($x), 'Got a blessed object');
isa_ok($x, 'X', '... of the expected class X');

is($x->str, 'aa', "Attribute 'str' is 'aa'");
cmp_deeply($m, {ypt => 'bb', sys => 'X'}, "Final meta hashref as expected");


done_testing();
