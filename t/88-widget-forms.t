#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use URI;
use Ferdinand;
use Ferdinand::DSL;

### Make sure we have all the pre-reqs we need for testing
eval "require Tenjin::Engine";
plan skip_all => "Skip this tests unless we can find original plTenjin: $@"
  if $@;


### Start the tests properly
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
                  execute sub { $_->stash->{clicked} };
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


my $ctx;
subtest 'Render call' => sub {
  is(
    exception {
      $ctx =
        $map->render('create',
        {id => [1], action_uri => URI->new('http://example.com/something')});
    },
    undef,
    "Render create lived"
  );
  ok($ctx->buffer, '... got a buffer with something in it');
};


subtest 'Buffer tests' => sub {
  my $buffer = $ctx->buffer;

  like($buffer, qr{action="/something"}, 'Form with expected action');
  like($buffer, qr{method="POST"},       'Form with expected method');
  like($buffer, qr{accept-charset="utf-8"},
    'Form with expected accept-encoding');

  like($buffer, qr{type="submit"},         'button with expected type');
  like($buffer, qr{$_="btn_w_2_my_label"}, "button with expected $_")
    for ('name', 'id');
};


done_testing();
