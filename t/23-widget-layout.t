#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::Widgets::Layout;

subtest 'layout' => sub {
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

subtest 'layout vs on_demand' => sub {
  my $item = bless({x => 1}, 'X');
  my $l = Ferdinand::Widgets::Layout->setup(
    { on_demand => 1,
      layout    => [
        { type => 'CB',
          cb   => sub { $_->item($item) }
        },
      ],
    }
  );

  my $ctx = _ctx();
  $l->render($ctx);
  is($ctx->item, undef, "Item empty as expected");

  $l->render_widgets($ctx);
  is($ctx->item, $item, "Item as expected");
};


done_testing();

sub _ctx {
  return Ferdinand::Context->new(
    map    => bless({}, 'Ferdinand::Map'),
    action => bless({}, 'Ferdinand::Action'),
    @_,
  );
}
