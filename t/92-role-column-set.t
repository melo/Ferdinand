#!perl

package Ferdinand::Widgets::X;
BEGIN { $INC{'Ferdinand/Widgets/X.pm'}++ }

use Ferdinand::Setup 'class';
with 'Ferdinand::Roles::Setup', 'Ferdinand::Roles::ColumnSet';

package main;

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::Widgets::Layout;

my $db = test_db();

my $l = setup_widget(
  'Layout',
  { layout => [
      { type   => 'DBIC::Source',
        source => sub { $db->source('I') }
      },
      { type    => 'X',
        columns => [
          'col1',
          'col2',
          'col3' => {a  => 1,   b => 2},
          'col4' => {c  => 'a', d => 'b'},
          'col5' => {as => 'xol5'},
        ],
      }
    ],
  }
);
my $x = $l->layout->[1];

cmp_deeply($x->col_names, [qw( col1 col2 col3 col4 xol5 )], 'Column names');
cmp_deeply(
  $x->col_meta,
  { col1 => {
      name        => 'col1',
      label       => 'Col1',
      is_required => 0,
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
    col2 => {
      name        => 'col2',
      label       => 'Col2',
      is_required => 0,
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
    col3 => {
      name        => 'col3',
      a           => 1,
      b           => 2,
      label       => 'Col3',
      is_required => 0,
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
    col4 => {
      name        => 'col4',
      c           => 'a',
      d           => 'b',
      label       => 'Col4',
      is_required => 0,
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
    xol5 => {
      name        => 'col5',
      label       => 'Col5',
      as          => 'xol5',
      is_required => 0,
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
  },
  'Column meta is cool'
);


my $link_to = sub { };
$l = setup_widget(
  'Layout',
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
          'html',
        ],
      }
    ],
  }
);
$x = $l->layout->[1];

ok($x, 'Got a widget object');
isa_ok($x, 'Ferdinand::Widgets::X', '... of the expected type');

my $n = $x->col_names;
is(scalar(@$n), 6, 'Five columns in our Set');

my $h = $x->col_meta;
cmp_deeply(
  $h->{id},
  { name        => 'id',
    data_type   => "integer",
    meta_type   => 'numeric',
    is_nullable => 0,
    label       => "ID",
    is_required => 1,
    _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
    _line       => re(qr{^\d+$}),
  },
  '... column id as expected'
);
cmp_deeply(
  $h->{slug},
  { name        => 'slug',
    data_type   => "varchar",
    meta_type   => 'text',
    is_nullable => 0,
    label       => "Slug",
    link_to     => $link_to,
    size        => 100,
    width       => 50,
    is_required => 1,
    _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
    _line       => re(qr{^\d+$}),
  },
  '... column slug as expected'
);

my $fmt = delete $h->{published_at}{formatter};
cmp_deeply(
  $h->{published_at},
  { name          => 'published_at',
    cls_list      => ["{sorter: 'eu_date'}"],
    cls_list_html => " class=\"{sorter: 'eu_date'}\"",
    data_type     => "date",
    meta_type     => 'date',
    is_nullable   => 0,
    default_value => ignore(),
    label         => "Published At",
    is_required   => 1,
    _file         => re(qr{Ferdinand/Roles/ColumnSet.pm}),
    _line         => re(qr{^\d+$}),
  },
  '... column published_at as expected'
);
cmp_deeply($h->{published_at}{default_value}->(),
  DateTime->today(), '...... default_value evals to the expected value');

cmp_deeply(
  $h->{html},
  { name        => 'html',
    data_type   => "text",
    meta_type   => 'text',
    label       => "Html",
    format      => "html",
    is_required => 1,
    _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
    _line       => re(qr{^\d+$}),
  },
  '... column id as expected'
);


done_testing();
