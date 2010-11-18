#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Ferdinand::Context;
use Ferdinand::Widgets::CB;
use Ferdinand::Widgets::Layout;
use Ferdinand::Widgets::DBIC::Source;
use Ferdinand::Widgets::DBIC::Item;
use Ferdinand::Widgets::DBIC::Set;

subtest 'Faked objects' => sub {
  my $l = Ferdinand::Widgets::Layout->setup(
    { layout => [
        { type   => 'DBIC::Source',
          source => sub { bless({source => 1}, 'DBIx::Class::ResultSource') },
        },
        { type => 'DBIC::Item',
          item => sub { bless({item => $_[1]->model}, 'DBIx::Class::Row') },
        },
        { type => 'DBIC::Set',
          set =>
            sub { bless({set => $_[1]->model}, 'DBIx::Class::ResultSet') },
        },
      ],
    }
  );

  my $ctx = _ctx();
  $l->render($ctx);

  my $source =
    bless {source => bless {source => 1}, 'DBIx::Class::ResultSource'},
    'Ferdinand::Model::DBIC';
  my $item = bless {item => $source}, 'DBIx::Class::Row';
  my $set  = bless {set  => $source}, 'DBIx::Class::ResultSet';

  cmp_deeply($ctx->model, $source, "Source as expected");
  cmp_deeply($ctx->item,  $item,   "Item as expected");
  cmp_deeply($ctx->set,   $set,    "Set as expected");
};


done_testing();

sub _ctx {
  return Ferdinand::Context->new(
    map    => bless({}, 'Ferdinand::Map'),
    action => bless({}, 'Ferdinand::Action'),
    @_,
  );
}
