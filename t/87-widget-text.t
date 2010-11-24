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
              type 'Text';
              columns {
                col 'title';
                col 'body';
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

  like($buffer, qr{<h1>Title</h1>}, "Buffer matches header '$_'")
    for ('ID', 'Body');

  like($buffer, qr{<h1>testing</h1>}, 'Matched header via markdown');
  like($buffer, qr{<li>$_</li>},      "Matched body item '$_'")
    for qw( first second third );
};


done_testing();
