#!perl

package X;

use Ferdinand::Setup 'class';
with 'Ferdinand::Roles::Setup', 'Ferdinand::Roles::ColumnSet';

package main;

use strict;
use warnings;
use Test::More;
use Test::Deep;

subtest 'Mock versions' => sub {
  my %m = (
    columns => [
      'col1',
      'col2',
      'col3' => {a => 1,   b => 2},
      'col4' => {c => 'a', d => 'b'},
    ],
  );

  my $x = X->setup(\%m);

  cmp_deeply($x->col_names, [qw( col1 col2 col3 col4 )], 'Column names');
  cmp_deeply(
    $x->col_meta,
    { col1 => {},
      col2 => {},
      col3 => {a => 1, b => 2},
      col4 => {c => 'a', d => 'b'},
    },
    'Column meta is cool'
  );
};


done_testing();
