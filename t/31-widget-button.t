#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::DSL;


### Make sure we have all the pre-reqs we need for testing
require_tenjin();


### Start the tests properly
my $map;
is(
  exception {
    $map = ferdinand_map {
      actions {
        create {
          form {
            button {
              label 'My label create';
              on_click {
                execute sub { $_->stash->{clicked} = 1 };
              };
            };
          };
        };

        edit {
          form {
            button {
              label 'My label edit';
              on_click {
                execute sub { $_->stash->{clicked} = 1 };
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


sub test_create_form {
  my $ctx    = shift;
  my $buffer = $ctx->buffer;

  like($buffer, qr{type="submit"}, 'button with expected type');
  like($buffer, qr{$_="btn_w_2_my_label_create"}, "button with expected $_")
    for ('name', 'id');
  like($buffer, qr{value="My label create"}, 'button with expected label');
  like(
    $buffer,
    qr{<input type="hidden" name="submited" value="1">},
    'make sure we have the submited marker on forms'
  );
}

subtest 'Render create form' => sub {
  my $ctx;

  is(
    exception {
      $ctx = $map->render(
        'create',
        { mode       => 'create',
          action_uri => URI->new('http://example.com/something')
        }
      );
    },
    undef,
    "Render create lived"
  );
  ok($ctx->buffer, '... got a buffer with something in it');
  is($ctx->stash->{clicked}, undef, '... button not submitted');
  test_create_form($ctx);

  is(
    exception {
      $ctx = $map->render(
        'create',
        { mode       => 'create_do',
          params     => {btn_w_2_my_label_create => 1},
          action_uri => URI->new('http://example.com/something'),
        }
      );
    },
    undef,
    "Render create_do lived"
  );
  ok($ctx->buffer, '... got a buffer with something in it');
  is($ctx->stash->{clicked}, 1, '... button submitted');
  test_create_form($ctx);
};


sub test_edit_form {
  my $ctx    = shift;
  my $buffer = $ctx->buffer;

  like($buffer, qr{type="submit"}, 'button with expected type');
  like($buffer, qr{$_="btn_w_2_my_label_edit"}, "button with expected $_")
    for ('name', 'id');
  like($buffer, qr{value="My label edit"}, 'button with expected label');
  like(
    $buffer,
    qr{<input type="hidden" name="submited" value="1">},
    'make sure we have the submited marker on forms'
  );
}

subtest 'Render edit form' => sub {
  my $ctx;

  is(
    exception {
      $ctx = $map->render(
        'edit',
        { mode       => 'edit',
          action_uri => URI->new('http://example.com/something')
        }
      );
    },
    undef,
    "Render edit lived"
  );
  ok($ctx->buffer, '... got a buffer with something in it');
  is($ctx->stash->{clicked}, undef, '... button not submitted');
  test_edit_form($ctx);

  is(
    exception {
      $ctx = $map->render(
        'edit',
        { mode       => 'edit_do',
          params     => {btn_w_2_my_label_edit => 1},
          action_uri => URI->new('http://example.com/something'),
        }
      );
    },
    undef,
    "Render edit_do lived"
  );
  ok($ctx->buffer, '... got a buffer with something in it');
  is($ctx->stash->{clicked}, 1, '... button submitted');
  test_edit_form($ctx);
};


done_testing();
