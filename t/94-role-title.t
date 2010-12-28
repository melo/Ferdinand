#!perl

package X1;

use Ferdinand::Setup 'class';
with 'Ferdinand::Roles::Title', 'Ferdinand::Roles::Setup';


package main;

use strict;
use warnings;
use Ferdinand::Tests;

my $ctx = Ferdinand::Context->new(
  map    => bless({}, 'Ferdinand::Map'),
  action => bless({}, 'Ferdinand::Action'),
  stash => {type => 'Magic'},
);

my $x;
is(exception { $x = X1->setup({title => 'xpto'}) },
  undef, 'Created X1, no exceptions');
is($x->title($ctx), 'xpto', '... title is ok');

is(
  exception {
    $x = X1->setup(
      { title => sub { $_->stash->{type} }
      }
    );
  },
  undef,
  'Created X1 again, no exceptions'
);
is($x->title($ctx), 'Magic', '... title is ok');

done_testing();
