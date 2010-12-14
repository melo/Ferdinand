#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;
use Test::Fatal;
use URI;
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
          create {
            form {
              button {
                label 'My label';
                on_click {
                  execute sub { $_->stash->{clicked} = 1 };
                };
              };
            };
          };

          edit {
            dbic_source { $db->source('I') };
            dbic_item { $_->model->source->resultset->find($_->id) };
            form {
              button {
                label 'My label';
                on_click {
                  execute sub {
                    $_->stash->{clicked} = 1;
                  };
                };
              };
            };
          };
        };
      };
    },
    undef,
    'Call to ferdinand_map() lived'
  );
};


subtest 'Render create form' => sub {
  my $ctx;

  is(
    exception {
      $ctx = $map->render(
        'create',
        { mode       => 'create',
          id         => [1],
          action_uri => URI->new('http://example.com/something')
        }
      );
    },
    undef,
    "Render create lived"
  );
  ok($ctx->buffer, '... got a buffer with something in it');
  is($ctx->stash->{clicked}, undef, '... button not submitted');

  is(
    exception {
      $ctx = $map->render(
        'create',
        { id         => [1],
          action_uri => URI->new('http://example.com/something'),
          mode       => 'create_do',
          params     => {btn_w_2_my_label => 1},
        }
      );
    },
    undef,
    "Render create_do lived"
  );
  ok($ctx->buffer, '... got a buffer with something in it');
  is($ctx->stash->{clicked}, 1, '... button submitted');

  subtest 'Test create buffer' => sub {
    my $buffer = $ctx->buffer;

    like($buffer, qr{action="/something"}, 'Form with expected action');
    like($buffer, qr{method="POST"},       'Form with expected method');
    like($buffer, qr{accept-charset="utf-8"},
      'Form with expected accept-encoding');

    like($buffer, qr{type="submit"},         'button with expected type');
    like($buffer, qr{$_="btn_w_2_my_label"}, "button with expected $_")
      for ('name', 'id');
  };
};


subtest 'Render edit form' => sub {
  my $ctx;

  is(
    exception {
      $ctx = $map->render(
        'edit',
        { mode       => 'edit',
          id         => [1],
          action_uri => URI->new('http://example.com/something')
        }
      );
    },
    undef,
    "Render edit lived"
  );
  ok($ctx->buffer, '... got a buffer with something in it');
  is($ctx->stash->{clicked}, undef, '... button not submitted');

  subtest 'Test edit buffer' => sub {
    my $buffer = $ctx->buffer;

    like($buffer, qr{action="/something"}, 'Form with expected action');
    like($buffer, qr{method="POST"},       'Form with expected method');
    like($buffer, qr{accept-charset="utf-8"},
      'Form with expected accept-encoding');

    like(
      $buffer,
      qr{<input type="hidden" name="id" value="1">},
      'Got a hidden field with the item ID'
    );

    like($buffer, qr{type="submit"},         'button with expected type');
    like($buffer, qr{$_="btn_w_4_my_label"}, "button with expected $_")
      for ('name', 'id');
  };

  is(
    exception {
      $ctx = $map->render(
        'edit',
        { id         => [1],
          action_uri => URI->new('http://example.com/something'),
          mode       => 'edit_do',
          params     => {btn_w_4_my_label => 1},
        }
      );
    },
    undef,
    "Render edit_do lived"
  );
  ok($ctx->buffer, '... got a buffer with something in it');
  is($ctx->stash->{clicked}, 1, '... button submitted');
};


done_testing();
