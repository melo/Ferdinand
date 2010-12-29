#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::DSL;


### Make sure we have all the pre-reqs we need for testing
my $db = test_db();
require_tenjin();


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

          edit {
            dbic_source { $db->source('I') };
            dbic_item { $_->model->source->resultset->find($_->id) };
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


subtest 'Render Tests' => sub {
  my @test_specs =
    (['create', DateTime->today->dmy('/')], ['edit', '10/10/2010'],);

  subtest 'Create/edit render' => sub {
    for my $ts (@test_specs) {
      my ($mode, $dmy) = @$ts;

      my $action = $map->action_for($mode);
      my $ctx    = render_ok(
        $action,
        { mode => $mode,
          id   => [1],
        },
        "Render action for mode '$mode'"
      );

      my $buffer = $ctx->buffer;
      ok($buffer, '... got a buffer with something in it');

      like(
        $buffer,
        qr{<th[^>]*>Published At:</th>},
        "Buffer matches header 'Published At'"
      );
      like($buffer, qr{value="$dmy"},
        '... Default value for published_at matches');
      like($buffer, qr{type="date"}, '... type for published_at matches');
    }
  };


  subtest 'Create render with errors', sub {
    for my $ts (@test_specs) {
      my ($mode, $dmy) = @$ts;

      my $action = $map->action_for($mode);
      my $ctx    = render_ok(
        $action,
        { mode   => 'create',
          errors => {published_at => 'error found'},
          id     => [1],
        },
        "Render action for mode '$mode'"
      );

      my $buffer = $ctx->buffer;
      ok($buffer, '... got a buffer with something in it');

      like(
        $buffer,
        qr{<th class="errof">Published At:</th>},
        "Buffer matches header with error 'Published At'"
      );
      like($buffer, qr{value="$dmy"},
        '... Default value for published_at matches');
      like($buffer, qr{type="date"}, '... type for published_at matches');
      like(
        $buffer,
        qr{<span class="errom">error found</span>},
        '... error found for published_at matches'
      );

    }
  };
};


done_testing();
