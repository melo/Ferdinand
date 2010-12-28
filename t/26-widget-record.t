#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::DSL;


### Make sure we have all the pre-reqs we need for testing
eval "require Tenjin::Engine";
plan skip_all => "Skip this tests unless we can find original plTenjin: $@"
  if $@;
my $db = test_db();


### Start the tests properly
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

          create {
            dbic_source { $db->source('I') };
            widget {
              type 'Record';
              columns {
                col 'published_at';
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


subtest 'View render' => sub {
  my $ctx;

  is(exception { $ctx = $map->render('view', {id => [1]}) },
    undef, "Rendered view didn't die");
  ok($ctx->buffer, '... got a buffer with something in it');

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
};


subtest 'Create render' => sub {
  my $ctx;

  is(exception { $ctx = $map->render('create', {mode => 'create'}) },
    undef, "Rendered create didn't die");
  ok($ctx->buffer, '... got a buffer with something in it');

  subtest 'Buffer tests' => sub {
    my $buffer = $ctx->buffer;

    like(
      $buffer,
      qr{<th[^>]*>Published At:</th>},
      "Buffer matches header 'Published At'"
    );

    my $dmy = DateTime->today->dmy('/');
    like($buffer, qr{value="$dmy"},
      '... Default value for published_at matches');
    like($buffer, qr{type="date"}, '... type for published_at matches');
  };
};


subtest 'Create render with errors', sub {
  my $action = $map->action_for('create');
  my $ctx    = Ferdinand::Context->new(
    map    => $map,
    action => $action,
    mode   => 'create',
    errors => {published_at => 'error found'},
  );

  is(
    exception {
      $action->render($ctx);
    },
    undef,
    "Rendered create with errors didn't die"
  );
  ok($ctx->buffer, '... got a buffer with something in it');

  subtest 'Buffer tests' => sub {
    my $buffer = $ctx->buffer;

    like(
      $buffer,
      qr{<th class="errof">Published At:</th>},
      "Buffer matches header with error 'Published At'"
    );

    my $dmy = DateTime->today->dmy('/');
    like($buffer, qr{value="$dmy"},
      '... Default value for published_at matches');
    like($buffer, qr{type="date"}, '... type for published_at matches');
    like(
      $buffer,
      qr{<span class="errom">error found</span>},
      '... error found for published_at matches'
    );
  };
};


done_testing();
