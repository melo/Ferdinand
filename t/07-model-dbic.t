#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::Model::DBIC;

subtest 'field values with live data' => sub {
  my $db     = test_db();
  my $source = $db->source('I');
  my $i      = $source->resultset->create(
    { title        => 'my title',
      slug         => 'slug_me',
      body         => 'a good one',
      html         => '<p>A good one indeed</p>',
      published_at => '2011-01-01',
      visible      => 'Y',
    }
  );
  $i->create_related(a => {name => 'Mini Me'});

  my $m = Ferdinand::Model::DBIC->new({source => $source});
  my $c = build_ctx(item => $i, model => $m);

  cmp_deeply(
    $m->field_value(ctx => $c, field => 'title'),
    [$i, 'title', 'my title'],
    'Simple fields work ok (object)'
  );
  cmp_deeply(
    $m->field_value(ctx => $c, field => 'a.name'),
    [$i->a, 'name', 'Mini Me'],
    'Complex fields work ok too (object)'
  );

  $i = {title => 'another title', a => {name => 'Maxi Pain'}};
  cmp_deeply(
    $m->field_value(ctx => $c, field => 'title', item => $i),
    [$i, 'title', 'another title'],
    'Simple fields work ok (hash)'
  );
  cmp_deeply(
    $m->field_value(ctx => $c, field => 'a.name', item => $i),
    [$i->{a}, 'name', 'Maxi Pain'],
    'Complex fields work ok too (hash)'
  );
};


subtest 'metadata with live data' => sub {
  my $db = test_db();
  my $w  = setup_widget(
    'Layout',
    { layout => [
        { type   => 'DBIC::Source',
          source => sub { $db->source('I') }
        },
        { type    => 'Record',
          columns => [
            qw(
              title slug body a.name
              a.listed_but_doesnt_exist
              no_relation.field
              )
          ]
        },
      ]
    }
  );
  my $m = $w->layout->[0]->model;

  cmp_deeply(
    $m->field_meta('title'),
    { data_type   => "varchar",
      is_nullable => 1,
      is_required => "",
      label       => "Title",
      meta_type   => "text",
      size        => 100,
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
    "Meta for field 'title' ok"
  );

  cmp_deeply(
    $m->field_meta('slug'),
    { data_type   => "varchar",
      is_nullable => 0,
      is_required => 1,
      label       => "Slug",
      meta_type   => "text",
      size        => 100,
      width       => 50,
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
    "Meta for field 'slug' ok"
  );

  cmp_deeply(
    $m->field_meta('body'),
    { data_type   => "text",
      is_required => 1,
      label       => "Body",
      meta_type   => "text",
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
    "Meta for field 'body' ok"
  );

  cmp_deeply(
    $m->field_meta('a.name'),
    { data_type   => "varchar",
      size        => 100,
      is_required => 1,
      is_nullable => 0,
      label       => "Name",
      meta_type   => "text",
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
    "Meta for field 'a.name' ok"
  );

  cmp_deeply(
    $m->field_meta('a.listed_but_doesnt_exist'),
    { is_required => 0,
      label       => "Listed But Doesnt Exist",
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
    "Meta for field 'a.listed_but_doesnt_exist' ok"
  );

  cmp_deeply(
    $m->field_meta('no_relation.field'),
    { is_required => 0,
      label       => "Field",
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => re(qr{^\d+$}),
    },
    "Meta for field 'no_relation.field' ok"
  );

  cmp_deeply($m->field_meta('a.not_a_field'),
    {}, "Meta for field 'a.not_a_field' ok");

  cmp_deeply($m->field_meta('not_a_relation.field_name'),
    {}, "Meta for field 'not_a_relation.field_name' ok");
};


done_testing();
