#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::DSL;


### Make sure we have all the pre-reqs we need for testing
require_tenjin();


### Start the tests proper
my $meta;
my $excp = exception {
  $meta = ferdinand_setup {
    actions {
      list {
        links {
          url 'Novo' => 'http://www.example.com/';
          url 'Titalo' => sub { $_->params->{url} };
        };
      };
      create {
        links {};
      };
    };
  };
};

is($excp, undef, 'No exception was trown');
diag("Exception detected: $excp") if $excp;

cmp_deeply(
  $meta,
  { actions => [
      { name   => 'list',
        layout => [
          { type  => 'Links',
            links => [
              {title => 'Novo',   url => 'http://www.example.com/'},
              {title => 'Titalo', url => ignore()},
            ],
          },
        ]
      },
      { name   => 'create',
        layout => [
          { type  => 'Links',
            links => [],
          },
        ]
      },
    ],
  },
  'Setup via DSL was fine'
);


my $m;
is(exception { $m = Ferdinand->setup(meta => $meta) },
  undef, 'Setup of Ferdinand ok');

my $ctx = $m->render('list', {mode => 'list', params => {url => 'xpto'}});
my $buf = $ctx->buffer;
ok($buf, 'Got something from render');

like($buf, qr{<div class="oplinks">}, '... proper div class for links');
like($buf, qr{<a href="http://www.example.com/">Novo</a>}, '... first link ok');
like($buf, qr{<a href="xpto">Titalo</a>}, '... second link ok');


done_testing();
