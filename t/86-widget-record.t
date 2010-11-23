#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;
use Test::Fatal;
use Ferdinand;
use Ferdinand::DSL;

### Make sure we have all the pre-reqs we need for testing
eval "require TDB";
plan skip_all => "Need DBIx::Class for live tests: $@" if $@;

eval "require Tenjin::Engine";
plan skip_all => "Skip this tests unless we can find original plTenjin: $@"
  if $@;


### Start the tests properly
my ($db, $tfh) = TDB->test_deploy;


my $map;
subtest 'Ferdinand setup' => sub {
  is(
    exception {
      $map = ferdinand_map {
        actions {
          view {
            dbic_source { $db->source('I') };
            dbic_item { $_->model->source->resultset->find($_->id) };
            widget {
              type 'Record';
              columns {
                col 'id';
                col 'title';
                link_to slug =>
                  sub { 'http://example.com/items/' . $_->slug };
                col 'published_at';
                col 'visible';
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
  is(exception { $ctx = $map->render('view', {id => [1]}) },
    undef, "Rendered view didn't die");
  ok($ctx->buffer, '... got a buffer with something in it');
};


subtest 'Buffer tests' => sub {
  my $buffer = $ctx->buffer;

  like($buffer, qr{<th[^>]*>$_:</th>}, "Buffer matches header '$_'")
    for ('ID', 'Title', 'Slug', 'Published At', 'Visible');

  my $row = $db->resultset('I')->find(1);

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
};


done_testing();
