#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Test::MockObject;
use Ferdinand::DSL;


my $db       = test_db();
my $title_cb = sub { join(' ', 'View for', $_->id) };
my $slug_cb  = sub { 'http://example.com/items/' . shift->slug };

my $meta;
my $excp = exception {
  $meta = ferdinand_setup {
    actions {
      list {
        title('My list title');

        dbic_source { $db->source('I') };
        dbic_set { $_->stash->{set} = $_; $_->model->source->result_set };

        header('My list header');

        widget {
          attr type => 'List';
          columns {
            link_to id => $slug_cb;
            link_to title => $slug_cb, {color => '#ff0', size => 75};
            link_to slug => $slug_cb, {color => '#ff0'};
            col('created_at');
            col('last_update_at');
            col('is_visible');
            col 'password' => {
              empty         => 1,
              skip_if_empty => 1,
              label         => 'Password FTW',
            };
          };
        };
      };

      view {
        title($title_cb);

        dbic_source { $db->source('I') };
        dbic_item {
          $_->stash->{item} = $_;
          $_->model->source->resultset->find(1);
        };

        execute { $_->stash->{cb_called} = $$ };
      };

      action {
        name('pop');

        layout {
          dbic_optional_item { undef };

          title('My pop title');
          nest {
            title('A little subtitle');
          }
        };
      };

      create {
        dbic_source { $db->source('I') };
        dbic_create { $_->stash->{valid} = 1 };
        title 'Create me';
      };

      edit {
        title 'Edit me';
        title 'Second edit me';
        dbic_source { $db->source('I') };
        dbic_apply {};

        prefix 'xpto' => sub {
          title 'Ypto';
          }
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
          { type   => 'DBIC::Source',
            source => ignore(),
          },
          { type => 'DBIC::Set',
            set  => ignore(),
          },
          { type   => 'Header',
            header => 'My list header',
          },
          { type    => 'List',
            columns => [
              id    => {link_to => $slug_cb},
              title => {
                link_to => $slug_cb,
                color   => '#ff0',
                size    => 75,
              },
              slug => {
                link_to => $slug_cb,
                color   => '#ff0',
              },
              'created_at',
              'last_update_at',
              'is_visible',
              password => {
                empty         => 1,
                skip_if_empty => 1,
                label         => 'Password FTW',
              },
            ],
          },
        ]
      },
      { name   => 'view',
        layout => [
          { type  => 'Title',
            title => $title_cb,
          },
          { type   => 'DBIC::Source',
            source => ignore(),
          },
          { type => 'DBIC::Item',
            item => ignore(),
          },
          { type => 'CB',
            cb   => ignore(),
          },
        ],
      },
      { name   => 'pop',
        layout => [
          {type => 'DBIC::Item', item => ignore(), required => 0},
          {type => 'Title', title => 'My pop title',},
          { type   => 'Layout',
            layout => [{type => 'Title', title => 'A little subtitle'}],
          },
        ],
      },
      { name   => 'create',
        layout => [
          {source => ignore(),    type => 'DBIC::Source'},
          {valid  => ignore(),    type => 'DBIC::Create'},
          {title  => 'Create me', type => 'Title'}
        ],
      },
      { name   => 'edit',
        layout => [
          {title  => 'Edit me',        type => 'Title'},
          {title  => 'Second edit me', type => 'Title'},
          {source => ignore(),         type => 'DBIC::Source'},
          {valid  => ignore(),         type => 'DBIC::Apply'},
          { overlay => {prefix => 'xpto'},
            type    => 'Layout',
            layout => [{title => 'Ypto', type => 'Title'}],
          },
        ],
      },
    ],
  },
  'Setup via DSL was fine'
);


my $m;
is(exception { $m = Ferdinand->setup_map($meta) },
  undef, 'Setup of Ferdinand ok');
isa_ok($m, 'Ferdinand::Map', '... expected base class');

subtest 'Basic render calls', sub {
  like(
    exception { $m->render('no_such_action') },
    qr/No action named 'no_such_action', /,
    'action not found throws exception'
  );

  my $action = $m->action_for('view');
  ok($action, 'Got an action for view');

  my $ctx;
  is(exception { $ctx = $m->render($action) },
    undef, 'Render with action object lives');
};

subtest 'List actions', sub {
  ok($m->has_action_for('list'), 'Our Ferdinand has a list action');
  my $action = $m->action_for('list');
  isnt($action, undef, '... and seem to have it');
  isa_ok($action, 'Ferdinand::Action');

  is(scalar($action->widgets), 5, 'Has five widgets');
  my ($t, $r, $s, $h, $l) = $action->widgets;

  is($t->title, 'My list title', 'Title title is ok');
  is($t->id,    'w_1',           '... and ID matches');

  is($h->header, 'My list header', 'Header header is ok');
  is($h->id,     'w_4',            '... and ID matches');

  my $col_names = $l->col_names;
  cmp_deeply($col_names,
    [qw( id title slug created_at last_update_at is_visible password )]);

  my $cols = $l->col_meta;
  cmp_deeply(
    $cols->{id},
    { data_type   => "integer",
      is_nullable => 0,
      is_required => 1,
      label       => "ID",
      link_to     => $slug_cb,
      meta_type   => "numeric",
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => ignore(),
    },
    'Meta for id ok'
  );
  cmp_deeply(
    $cols->{title},
    { data_type   => "varchar",
      is_required => '',
      is_nullable => 1,
      label       => "Title",
      link_to     => $slug_cb,
      meta_type   => "text",
      size        => 75,
      color       => '#ff0',
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => ignore(),
    },
    'Meta for title ok'
  );
  cmp_deeply(
    $cols->{slug},
    { data_type   => "varchar",
      is_nullable => 0,
      is_required => 1,
      label       => "Slug",
      link_to     => $slug_cb,
      meta_type   => "text",
      size        => 100,
      width       => 50,
      color       => '#ff0',
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => ignore(),
    },
    'Meta for slug ok'
  );
  cmp_deeply(
    $cols->{is_visible},
    { is_required => 0,
      label       => "Is Visible",
      _file       => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line       => ignore(),
    },
    'Meta for is_visible ok'
  );
  cmp_deeply(
    $cols->{password},
    { empty         => 1,
      skip_if_empty => 1,
      is_required   => 0,
      label         => 'Password FTW',
      _file         => re(qr{Ferdinand/Roles/ColumnSet.pm}),
      _line         => ignore(),
    },
    'Meta for password ok'
  );

  is($l->id, 'w_5', 'List widget ID matches');

  ok(all_unique(map { $_->id } $action->widgets), 'All IDs are unique');
};

subtest 'Pop action' => sub {
  ok($m->has_action_for('pop'), 'Our Ferdinand has a pop action');
  my $action = $m->action_for('pop');
  isa_ok($action, 'Ferdinand::Action', '... proper class for action');

  my @widgets = $action->widgets;
  is(scalar(@widgets), 3, 'Three widgets in this layout');
  is(ref($widgets[1]), 'Ferdinand::Widgets::Title',
    'Expected type for first widget');
  is($widgets[1]->title, 'My pop title', '... title text is ok');

  is(ref($widgets[2]), 'Ferdinand::Widgets::Layout',
    'Expected type for second widget');

  @widgets = $widgets[2]->widgets;
  is(ref($widgets[0]), 'Ferdinand::Widgets::Title',
    'Expected type for first subwidget');
  is($widgets[0]->title, 'A little subtitle', '... title text is ok');

  ok(all_unique(map { $_->id } $action->widgets), 'All IDs are unique');
};


subtest 'View action' => sub {
  ok($m->has_action_for('view'), 'Our Ferdinand has a view action');
  my $action = $m->action_for('view');
  isa_ok($action, 'Ferdinand::Action', '... proper class for action');

  my @widgets = $action->widgets;
  is(scalar(@widgets), 4, 'Four widgets in this layout');
  is(ref($widgets[0]), 'Ferdinand::Widgets::Title',
    'Expected type for widget');
  is($widgets[0]->title, $title_cb, 'Title cb is ok');

  my $ctx;
  is(exception { $ctx = $m->render('view', {id => ['yuppii']}) },
    undef, "Render didn't die");

  is($ctx->stash->{title}, 'View for yuppii', 'Dynamic title as expected');
  is($ctx->stash->{item}, $ctx, 'dbic_item() called with the expected $_');
  is($ctx->stash->{cb_called}, $$, 'execute() called with the expected $_');

  ok(all_unique(map { $_->id } $action->widgets), 'All IDs are unique');
};


subtest 'Create action' => sub {
  ok($m->has_action_for('create'), 'Our Ferdinand has a create action');
  my $action = $m->action_for('create');
  isa_ok($action, 'Ferdinand::Action', '... proper class for action');

  my @widgets = $action->widgets;
  is(scalar(@widgets), 3, 'Three widgets in this layout');

  my ($r, $c, $t) = @widgets;

  is(
    ref($c),
    'Ferdinand::Widgets::DBIC::Create',
    'Expected type for widget 1'
  );

  is(ref($t), 'Ferdinand::Widgets::Title', 'Expected type for widget 2');
  is($t->title, 'Create me', 'Title text is ok');

  my $ctx;
  is(exception { $ctx = $m->render('create') }, undef, "Render didn't die");

  my $s = $ctx->stash;
  is($s->{title}, 'Create me', 'Stashed title is fine');
  is($s->{valid}, 1,           'Stashed validation is fine');

  ok(all_unique(map { $_->id } $action->widgets), 'All IDs are unique');
};


subtest 'Edit action' => sub {
  ok($m->has_action_for('edit'), 'Our Ferdinand has a edit action');
  my $action = $m->action_for('edit');
  isa_ok($action, 'Ferdinand::Action', '... proper class for action');

  my @widgets = $action->widgets;
  is(scalar(@widgets), 5, 'Fice widgets in this layout');

  my ($w1, $w2) = @widgets;

  is(ref($w1),   'Ferdinand::Widgets::Title', 'Expected type for widget 1');
  is($w1->title, 'Edit me',                   '... title matches');
  is($w1->id,    'w_1',                       '... id matches');

  is(ref($w2),   'Ferdinand::Widgets::Title', 'Expected type for widget 2');
  is($w2->title, 'Second edit me',            '... title matches');
  is($w2->id,    'w_2',                       '... id matches');

  ok(all_unique(map { $_->id } $action->widgets), 'All IDs are unique');
};


done_testing();

sub all_unique {
  my %unique;
  @unique{@_} = @_;
  return scalar(@_) == scalar(keys %unique);
}
