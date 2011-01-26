#!perl

package X;

use Ferdinand::Setup 'class';
use Method::Signatures;
use Guard;
with 'Ferdinand::Roles::Setup';

has 'stash' => (isa => 'HashRef', is => 'rw');
has 'str'   => (isa => 'Str',     is => 'ro');
has 'end'   => (isa => 'Str',     is => 'rw');
has 'extra' => (isa => 'Str',     is => 'ro');

after setup_fields => method($fields) {push @$fields, 'extra'};

after setup_attrs => method ($class:, $attrs, $meta, $sys, $stash) {
  $attrs->{str}   = delete $meta->{str} if exists $meta->{str};
  $attrs->{stash} = $stash;
  $stash->{end}   = 'called';

  $stash->{setup_attrs}++;
};


method setup_done ($stash) {
  $self->end($stash->{end});
}

method setup_check_begin ($ctx, $guards) {
  my $s = $ctx->stash;
  
  $s->{setup_check_begin}++;
  push @$guards, guard { $s->{setup_check_begin_guard}++ };
}

method setup_check_self ($ctx) {
  my $s = $ctx->stash;
  
  $s->{setup_check_self} = ++$s->{setup_check_begin_guard};
}


package main;

use strict;
use warnings;
use Ferdinand::Tests;

my $m = {str => 'aa', extra => 'e'};
my $x = Ferdinand->setup('X', $m);

ok($x, 'Got something');
isa_ok($x, 'X', '... of the expected class X');

is($x->str,   'aa',     "Attribute 'str' is 'aa'");
is($x->extra, 'e',      "Attribute 'extra' is 'e'");
is($x->end,   'called', 'setup_done() called properly');
cmp_deeply(
  $x->stash,
  { end                     => 'called',
    setup_attrs             => 1,
    setup_check_begin       => 1,
    setup_check_self        => 1,
    setup_check_begin_guard => 2,
    widget_ids              => ignore(),
  },
  'Stash as expected'
);


done_testing();
