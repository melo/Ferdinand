#!perl

package Ferdinand::Widgets::X;
BEGIN { $INC{'Ferdinand/Widgets/X.pm'}++ }

use Ferdinand::Setup 'class';
with 'Ferdinand::Roles::Setup', 'Ferdinand::Roles::ColumnSet';

package main;

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;
use Ferdinand::Widgets::Layout;

subtest 'Mock versions' => sub {
  my %m = (
    columns => [
      'col1',
      'col2',
      'col3' => {a => 1,   b => 2},
      'col4' => {c => 'a', d => 'b'},
    ],
  );

  my $x = Ferdinand::Widgets::X->setup(\%m);

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


subtest 'Live ColumnSet role tests' => sub {
  eval "require TDB";
  plan skip_all => "Could not load test database, probably missing DBIC: $@"
    if $@;

  my ($db, $tfh) = TDB->test_deploy;

  my $link_to = sub { };
  my $l = Ferdinand::Widgets::Layout->setup(
    { layout => [
        { type   => 'DBIC::Source',
          source => sub { $db->source('I') },
        },
        { type    => 'X',
          columns => [
            'id',
            'title' => {linked  => 'view'},
            'slug'  => {link_to => $link_to},
            'published_at',
            'visible',
          ],
        }
      ],
    }
  );

  my $x = $l->layout->[1];
  ok($x, 'Got a widget object');
  isa_ok($x, 'Ferdinand::Widgets::X', '... of the expected type');

  my $n = $x->col_names;
  is(scalar(@$n), 5, 'Five columns in our Set');

  my $h = $x->col_meta;
  cmp_deeply(
    $h->{id},
    { data_type     => "integer",
      is_nullable   => 0,
      label         => "ID",
    },
    '... column id as expected'
  );
  cmp_deeply(
    $h->{slug},
    { data_type     => "varchar",
      is_nullable   => 0,
      label         => "Slug",
      link_to       => $link_to,
      size          => 100,
    },
    '... column slug as expected'
  );

  my $fmt = delete $h->{published_at}{formatter};
  cmp_deeply(
    $h->{published_at},
    { cls_list      => ["{sorter: 'eu_date'}"],
      cls_list_html => " class=\"{sorter: 'eu_date'}\"",
      data_type     => "date",
      is_nullable   => 0,
      default_value => ignore(),
      label         => "Published At",
    },
    '... column published_at as expected'
  );
  cmp_deeply($h->{published_at}{default_value}->(),
    DateTime->today(), '...... default_value evals to the expected value');
};


done_testing();
