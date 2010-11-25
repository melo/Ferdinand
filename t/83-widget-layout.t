#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;
use Test::Fatal;
use Ferdinand::Widgets::CB;
use Ferdinand::Widgets::Layout;
use Ferdinand::Context;

subtest 'layout no clone' => sub {
  my $ctx = _ctx();
  my $l   = Ferdinand::Widgets::Layout->setup(
    { layout => [
        { type => 'CB',
          cb   => sub { $_->item(bless({x => 1}, 'X')) },
        },
        {type => '+TestWidget'},
      ],
    }
  );

  isa_ok($l, 'Ferdinand::Widgets::Layout',
    'Class name for Layout widget object ok');

  is(exception { $l->render($ctx) }, undef, 'Render ok');
  cmp_deeply($ctx->item, bless({x => 1}, 'X'), "Item as expected");

  is($ctx->stash->{titi}, "TestWidget $$", 'Support for +WidgetClass');
};

subtest 'layout with clone' => sub {
  my $ctx = _ctx();

  my $l = Ferdinand::Widgets::Layout->setup(
    { clone  => 1,
      layout => [
        { type => 'CB',
          cb   => sub { $_->item(bless({x => 1}, 'X')) }
        },
      ],
    }
  );

  isa_ok($l, 'Ferdinand::Widgets::Layout',
    'Class name for Layout widget object ok');

  $l->render($ctx);
  is($ctx->item, undef, "Item as expected");
};


done_testing();

sub _ctx {
  return Ferdinand::Context->new(
    map    => bless({}, 'Ferdinand::Map'),
    action => bless({}, 'Ferdinand::Action'),
    @_,
  );
}
