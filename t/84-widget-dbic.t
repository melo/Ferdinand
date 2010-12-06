#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;
use Ferdinand::Context;
use Ferdinand::Widgets::Layout;
use Ferdinand::Widgets::DBIC::Source;
use Ferdinand::Widgets::DBIC::Item;
use Ferdinand::Widgets::DBIC::Set;

subtest 'Faked objects' => sub {
  my $l = Ferdinand::Widgets::Layout->setup(
    { layout => [
        { type   => 'DBIC::Source',
          source => sub { bless({source => 1}, 'DBIx::Class::ResultSource') },
        },
        { type => 'DBIC::Item',
          item => sub { bless({item => $_[1]->model}, 'DBIx::Class::Row') },
        },
        { type => 'DBIC::Set',
          set =>
            sub { bless({set => $_[1]->model}, 'DBIx::Class::ResultSet') },
        },
      ],
    }
  );

  my $ctx = _ctx();
  $l->render($ctx);

  my $source =
    bless {source => bless {source => 1}, 'DBIx::Class::ResultSource'},
    'Ferdinand::Model::DBIC';
  my $item = bless {item => $source}, 'DBIx::Class::Row';
  my $set  = bless {set  => $source}, 'DBIx::Class::ResultSet';

  cmp_deeply($ctx->model, $source, "Source as expected");
  cmp_deeply($ctx->item,  $item,   "Item as expected");
  cmp_deeply($ctx->set,   $set,    "Set as expected");
};

subtest 'Live DB' => sub {
  eval "require TDB";
  plan skip_all => "Could not load test database, probably missing DBIC: $@"
    if $@;

  my ($db, $tfh) = TDB->test_deploy;

  my $l = Ferdinand::Widgets::Layout->setup(
    { layout => [
        { type   => 'DBIC::Source',
          source => sub { $db->source('I') },
        },
        { type => 'DBIC::Item',
          item => sub { $db->resultset('I')->find(1) },
        },
        { type => 'DBIC::Set',
          set  => sub { $db->resultset('I') },
        },
      ],
    }
  );

  my $ctx = _ctx();
  $l->render($ctx);

  my $s = $ctx->model->source;
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
  eval "require TDB";
  plan skip_all => "Could not load test database, probably missing DBIC: $@"
    if $@;

  my ($db, $tfh) = TDB->test_deploy;

  my $l = Ferdinand::Widgets::Layout->setup(
    { layout => [
        { type   => 'DBIC::Source',
          source => sub { $db->source('I') },
        },
        { type => 'DBIC::Item',
          item => sub { $db->resultset('I')->find(1) },
        },
        { type    => '+TestRenderField',
          columns => [
            'slug' => {
              link_to => sub { 'http://example.com/' . $_->slug }
            },
            'published_at',
            'visible',
            'title',
          ],
        },
      ],
    }
  );

  my $ctx = _ctx();
  $l->render($ctx);

  my $cm = $ctx->stash->{col_meta};
  is($ctx->render_field(field => 'visible', meta => $cm->{visible}),
    'V', 'Field visible ok');
  is(
    $ctx->render_field(field => 'title', meta => $cm->{title}),
    'Title 1 &amp; me',
    'Field title ok'
  );
  is($ctx->render_field(field => 'published_at', meta => $cm->{published_at}),
    '10/10/2010', 'Field published_at ok');
  is(
    $ctx->render_field(field => 'slug', meta => $cm->{slug}),
    '<a href="http://example.com/title_1">title_1</a>',
    'Field slug ok'
  );

  cmp_deeply(
    [keys(%$cm)],
    bag(qw(published_at slug title visible)),
    'Expected fields'
  );
  cmp_deeply(
    $cm->{title},
    { cls_list      => [],
      cls_list_html => "",
      data_type     => "varchar",
      label         => "Title",
      size          => 100,
    },
    "... meta for field 'title' ok"
  );
  cmp_deeply(
    $cm->{visible},
    { cls_list      => [],
      cls_list_html => "",
      data_type     => "char",
      is_nullable   => 0,
      label         => "Visible",
      size          => 1,
      options       => [qw( H V )],
    },
    "... meta for field 'visible' ok"
  );
  cmp_deeply(
    $cm->{published_at},
    { cls_list      => ["{sorter: 'eu_date'}"],
      cls_list_html => " class=\"{sorter: 'eu_date'}\"",
      data_type     => "date",
      formatter     => ignore(),
      is_nullable   => 0,
      label         => "Published At",
    },
    "... meta for field 'published_at' ok"
  );
  cmp_deeply(
    $cm->{slug},
    { cls_list      => [],
      cls_list_html => "",
      data_type     => "varchar",
      is_nullable   => 0,
      label         => "Slug",
      link_to       => ignore(),
      size          => 100,
    },
    "... meta for field 'slug' ok"
  );
};


done_testing();

sub _ctx {
  return Ferdinand::Context->new(
    map    => bless({}, 'Ferdinand::Map'),
    action => bless({}, 'Ferdinand::Action'),
    @_,
  );
}
