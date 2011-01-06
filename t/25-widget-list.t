#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::DSL;

### Make sure we have all the pre-reqs we need for testing
require_tenjin();
my $db = test_db();

my $map;
subtest 'Ferdinand setup' => sub {
  my $link_to_cb = sub { 'http://example.com/items/' . shift->slug };
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
                link_to id    => $link_to_cb;
                link_to title => $link_to_cb;
                link_to slug  => $link_to_cb;
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


subtest 'Render list action' => sub {
  my $ctx;

  is(exception { $ctx = $map->render('list') },
    undef, "Rendered list didn't die");
  ok($ctx->buffer, '... got a buffer with something in it');

  my $buffer = $ctx->buffer;

  like($buffer, qr{<th[^>]*>$_</th>}, "Buffer matches header '$_'")
    for ('ID', 'Title', 'Slug', 'Published At', 'Visible');

  for my $row ($db->resultset('I')->all) {
    my $id   = $row->id;
    my $slug = $row->slug;

    ok($row, "Got row $id");
    like(
      $buffer,
      qr{<td><a href="http://example.com/items/$slug">$id</a></td>},
      '... ID matches'
    );

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
