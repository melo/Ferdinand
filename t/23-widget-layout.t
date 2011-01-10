#!perl

use strict;
use warnings;
use Ferdinand::Tests;


subtest 'layout' => sub {
  my $l = setup_widget(
    'Layout',
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

  my $ctx = render_ok($l);
  cmp_deeply($ctx->item, bless({x => 1}, 'X'), "Item as expected");
  is($ctx->stash->{titi}, "TestWidget $$", 'Support for +WidgetClass');
};


subtest 'layout vs on_demand' => sub {
  my $item = bless({x => 1}, 'X');
  my $l = setup_widget(
    'Layout',
    { on_demand => 1,
      layout    => [
        { type => 'CB',
          cb   => sub { $_->item($item) }
        },
      ],
    }
  );

  my $ctx = render_ok($l);
  is($ctx->item, undef, "Item empty as expected");

  $l->render_widgets($ctx);
  is($ctx->item, $item, "Item as expected");
};


subtest 'layout with overlay' => sub {
  my $l = setup_widget(
    'Layout',
    { overlay => {prefix => 'my prefix'},
      layout  => [
        { type => 'CB',
          cb   => sub { $_->stash(prefix => $_->prefix) }
        },
      ],
    }
  );

  my $ctx = render_ok($l);
  is($ctx->stash->{prefix}, 'my prefix', 'Prefix as expected inside layout');
};


done_testing();
