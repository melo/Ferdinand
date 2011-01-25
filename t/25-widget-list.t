#!perl

use strict;
use warnings;
use utf8;
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

          view {
            dbic_source { $db->source('I') };
            dbic_set { $db->resultset('I')->search({id => -1}) };
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

  for my $mode (qw(view list create create_do edit edit_do)) {
    is(exception { $ctx = $map->render('list', {mode => $mode}) },
      undef, "Rendered list didn't die (mode $mode)");

    my $buffer = $ctx->buffer;
    ok($ctx->buffer, '... got a buffer with something in it');

    like($buffer, qr{<th[^>]*>$_</th>}, "...... buffer matches header '$_'")
      for ('ID', 'Title', 'Slug', 'Published At', 'Visible');

    for my $row ($db->resultset('I')->all) {
      my $id   = $row->id;
      my $slug = $row->slug;

      ok($row, "... Test with row $id");
      like(
        $buffer,
        qr{<td><a href="http://example.com/items/$slug">$id</a></td>},
        '...... ID matches'
      );

      like(
        $buffer,
        qr{<td><a href="http://example.com/items/$slug">$slug</a></td>},
        '...... Slug matches'
      );

      my $dmy = $row->published_at->dmy('/');
      like($buffer, qr{<td>$dmy</td>}, '...... Date published_at matches');

      my $visible = $row->visible;
      like($buffer, qr{<td>$visible</td>}, '...... Visibility matches');
    }
  }
};


subtest 'Render empty list' => sub {
  my $ctx;

  is(exception { $ctx = $map->render('view') },
    undef, "Rendered view didn't die");
  my $buffer = $ctx->buffer;

  ok($buffer, '... got a buffer with something in it');
  like(
    $buffer,
    qr{<tr><td colspan="\d+">Não existem registos para listar</td></tr>},
    '... proper warning message found'
  );
};


done_testing();
