#!perl

use strict;
use warnings;
use Ferdinand::Tests;

require_tenjin();

my $db     = test_db();
my $set    = $db->resultset('I');
my $item   = $set->find(1);
my $source = $set->result_source;


subtest 'Basic DBIC model elements' => sub {
  my $f = setup_widget(
    'Form',
    { layout => [
        { type   => 'DBIC::Source',
          source => sub {$source},
        },
        { type => 'DBIC::Item',
          item => sub {$item},
        },
        { type => 'DBIC::Set',
          set  => sub {$set},
        },
      ],
    }
  );

  my $ctx = render_ok($f);

  my $model = $ctx->model;
  cmp_deeply(
    [$model->columns],
    [qw(id title slug body html published_at visible)],
    'Model columns() works'
  );
  cmp_deeply([$model->primary_columns],
    [qw(id)], '... primary_columns() also works');

  is($model->source, $source, '... source lives on as expected');
  is($ctx->item,     $item,   '... item lives on as expected');
  is($ctx->set,      $set,    '... set lives on as expected');

  my $s = $model->source;
  ok($s, 'Got a source');
  isa_ok($s, 'DBIx::Class::ResultSource', '... of the expected type');
  ok($s->has_column($_), "... has column $_")
    for qw(id title slug published_at visible);

  my $i = $ctx->item;
  ok($i, 'Got an item');
  isa_ok($i, 'TDB::Result::I', '... of the expected type');
  is($i->id, 1, '... expected ID');
  is($i->title, 'Title 1 & me', '... expected title');
  isa_ok($i->published_at, 'DateTime', '... expected type of published_at');

  my $t = $ctx->set;
  ok($t, 'Got a set');
  isa_ok($t, 'DBIx::Class::ResultSet', '... of the expected type');
  is($t->count, 2, '... with the expected count of results');
};


subtest 'Render Field' => sub {
  my $f = setup_widget(
    'Form',
    { layout => [
        { type   => 'DBIC::Source',
          source => sub {$source},
        },
        { type => 'DBIC::Item',
          item => sub {$item},
        },
        { type    => '+TestRenderField',
          columns => [
            'slug' => {
              link_to => sub { 'http://example.com/' . shift->slug }
            },
            'published_at',
            'visible',
            'title',
          ],
        },
      ],
    }
  );

  my $ctx = render_ok($f);
TODO: {
    local $TODO =
      "Fix model leak: all containers should start a overlay to cleanup after all child widgets are rendered";
    is($ctx->model, undef,
      'Last model seen is still visible from the outside');
  }

  ## Fake it :)
  $ctx->model(($f->widgets)[0]->model);

  is($ctx->render_field(field => 'visible'), 'V', 'Field visible ok');
  is(
    $ctx->render_field(field => 'title'),
    'Title 1 &amp; me',
    'Field title ok'
  );

  is($ctx->render_field(field => 'published_at'),
    '10/10/2010', 'Field published_at ok');
  is(
    $ctx->render_field(field => 'slug'),
    '<a href="http://example.com/title_1">title_1</a>',
    'Field slug ok'
  );

  my $cm = $ctx->model->_field_meta;
  cmp_deeply(
    [keys(%$cm)],
    bag(qw(published_at slug title visible)),
    'Expected fields'
  );
  cmp_deeply(
    $cm->{title},
    { name        => 'title',
      field       => 'title',
      data_type   => 'varchar',
      label       => 'Title',
      size        => 100,
      is_required => '',
      is_nullable => 1,
      meta_type   => 'text',
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => ignore(),
    },
    "... meta for field 'title' ok"
  );
  cmp_deeply(
    $cm->{visible},
    { name          => 'visible',
      field         => 'visible',
      data_type     => "char",
      is_nullable   => 0,
      label         => "Visible",
      size          => 1,
      default_value => 'H',
      options       => [
        {id => 'H', text => 'H'},
        {id => 'V', text => 'V'},
        {id => 'Z', text => 'ZZ'},
      ],
      is_required => 1,
      meta_type   => 'text',
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => ignore(),
    },
    "... meta for field 'visible' ok"
  );
  cmp_deeply(
    $cm->{published_at},
    { name          => 'published_at',
      field         => 'published_at',
      cls_list      => ["{sorter: 'eu_date'}"],
      cls_list_html => " class=\"{sorter: 'eu_date'}\"",
      data_type     => "date",
      formatter     => ignore(),
      is_nullable   => 0,
      default_value => ignore(),
      label         => "Published At",
      is_required   => 1,
      meta_type     => 'date',
      _file         => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line         => ignore(),
    },
    "... meta for field 'published_at' ok"
  );
  cmp_deeply($cm->{published_at}{default_value}->(),
    DateTime->today(), '...... default_value evals to the expected value');
  cmp_deeply(
    $cm->{slug},
    { name        => 'slug',
      field       => 'slug',
      data_type   => "varchar",
      is_nullable => 0,
      label       => "Slug",
      link_to     => ignore(),
      size        => 100,
      width       => 50,
      is_required => 1,
      meta_type   => 'text',
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => ignore(),
    },
    "... meta for field 'slug' ok"
  );
};


done_testing();
