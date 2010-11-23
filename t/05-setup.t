#!perl

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MockObject;
use Ferdinand;
use Ferdinand::DSL;


my $source = bless {}, 'DBIx::Class::ResultSource';
{
  no strict 'refs';
  *{'DBIx::Class::ResultSource::column_info'} = sub { {} };
}


my $title_cb = sub { join(' ', 'View for', $_->id) };
my $slug_cb = sub { 'http://example.com/items/' . $_->slug };

my $meta;
my $excp = exception {
  $meta = ferdinand_setup {
    actions {
      list {
        title('My list title');

        widget {
          type 'List';
          columns {
            linked id    => 'view';
            linked title => 'view';
            link_to slug => $slug_cb;
            col('created_at');
            col('last_update_at');
            col('is_visible');
          };
        };
      };

      view {
        title($title_cb);

        dbic_item { $_->stash->{item} = $_ };
        dbic_set { $_->stash->{set} = $_ };
      };

      action {
        name('pop');

        layout {
          title('My pop title');
        };
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
          { type  => 'Title',
            title => 'My list title',
          },
          { type    => 'List',
            columns => [
              id    => {linked  => 'view'},
              title => {linked  => 'view'},
              slug  => {link_to => $slug_cb},
              'created_at',
              'last_update_at',
              'is_visible',
            ],
          },
        ]
      },
      { name   => 'view',
        layout => [
          { type  => 'Title',
            title => $title_cb,
          },
          { type => 'DBIC::Item',
            item => ignore(),
          },
          { type => 'DBIC::Set',
            set  => ignore(),
          },
        ],
      },
      { name   => 'pop',
        layout => [{title => 'My pop title', type => 'Title'}],
      },
    ],
  },
  'Setup via DSL was fine'
);


my $m;
is(exception { $m = Ferdinand->setup(meta => $meta) },
  undef, 'Setup of Ferdinand ok');
isa_ok($m, 'Ferdinand::Map', '... expected base class');

subtest 'List actions', sub {
  ok($m->has_action_for('list'), 'Our Ferdinand has a list action');
  my $action = $m->action_for('list');
  isnt($action, undef, '... and seem to have it');
  isa_ok($action, 'Ferdinand::Action');

  is(scalar($action->widgets), 2, 'Has two widgets');
  my ($t, $l) = $action->widgets;

  is($t->title, 'My list title');

  my $col_names = $l->col_names;
  is(scalar(@$col_names), 6, 'Number of columns is ok');
  cmp_deeply($col_names,
    [qw( id title slug created_at last_update_at is_visible )]);

  my $cols = $l->col_meta;
  cmp_deeply($cols->{id},    {linked  => 'view'},   'Meta for id ok');
  cmp_deeply($cols->{title}, {linked  => 'view'},   'Meta for title ok');
  cmp_deeply($cols->{slug},  {link_to => $slug_cb}, 'Meta for slug ok');
  cmp_deeply($cols->{is_visible}, {}, 'Meta for is_visible ok');
};

subtest 'Pop action' => sub {
  ok($m->has_action_for('pop'), 'Our Ferdinand has a pop action');
  my $action = $m->action_for('pop');
  isa_ok($action, 'Ferdinand::Action', '... proper class for action');

  my @widgets = $action->widgets;
  is(scalar(@widgets), 1, 'One widget in this layout');
  is(ref($widgets[0]), 'Ferdinand::Widgets::Title',
    'Expected type for widget');
  is($widgets[0]->title, 'My pop title', 'Title text is ok');
};


subtest 'View action' => sub {
  ok($m->has_action_for('view'), 'Our Ferdinand has a view action');
  my $action = $m->action_for('view');
  isa_ok($action, 'Ferdinand::Action', '... proper class for action');

  my @widgets = $action->widgets;
  is(scalar(@widgets), 3, 'Three widgets in this layout');
  is(ref($widgets[0]), 'Ferdinand::Widgets::Title',
    'Expected type for widget');
  is($widgets[0]->title, $title_cb, 'Title cb is ok');

  my $ctx;
  is(exception { $ctx = $m->render('view', {id => ['yuppii']}) },
    undef, "Render didn't die");

  is($ctx->stash->{title}, 'View for yuppii', 'Dynamic title as expected');
  is($ctx->stash->{item}, $ctx, 'dbic_item() called with the expected $_');
  is($ctx->stash->{set},  $ctx, 'dbic_set() called with the expected $_');
};


done_testing();
