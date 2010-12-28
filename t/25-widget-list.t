#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::DSL;

### Make sure we have all the pre-reqs we need for testing
plan skip_all => "Skip this tests unless we can find original plTenjin: $@"
  if $@;
my $db = test_db();

my $map;
subtest 'Ferdinand setup' => sub {
  is(
    exception {
      $map = ferdinand_map {
        actions {
          list {
            dbic_source { $db->source('I') };
            dbic_set { $_->model->source->resultset };
            widget {
              type 'List';
              columns {
                linked id    => 'view';
                linked title => 'view';
                link_to slug =>
                  sub { 'http://example.com/items/' . $_->slug };
                col('published_at');
                col('visible');
              };
            };
          };
        };
      }
    },
    undef,
    'Call to ferdinand_map() lived'
  );
};


my $ctx;
subtest 'Render call' => sub {
  is(exception { $ctx = $map->render('list') },
    undef, "Rendered list didn't die");
  ok($ctx->buffer, '... got a buffer with something in it');
};


subtest 'Result tests' => sub {
  my $buffer = $ctx->buffer;

  like($buffer, qr{<th[^>]*>$_</th>}, "Buffer matches header '$_'")
    for ('ID', 'Title', 'Slug', 'Published At', 'Visible');

  for my $row ($db->resultset('I')->all) {
    my $id = $row->id;

    ok($row, "Got row $id");
    like($buffer, qr{<td>$id</td>}, '... ID matches');

    my $slug = $row->slug;
    like(
      $buffer,
      qr{<td><a href="http://example.com/items/$slug">$slug</a></td>},
      '... Slug matches'
    );

    my $dmy = $row->published_at->dmy('/');
    like($buffer, qr{<td>$dmy</td>}, '... Date published_at matches');

    my $visible = $row->visible;
    like($buffer, qr{<td>$visible</td>}, '... Visibility matches');
  }
};


done_testing();
