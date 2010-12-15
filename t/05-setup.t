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

        header('My list header');

        widget {
          attr type => 'List';
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

        execute { $_->stash->{cb_called} = $$ };
      };

      action {
        name('pop');

        layout {
          title('My pop title');
        };
      };

      create {
        dbic_create { $_->stash->{valid} = 1 };
        title 'Create me';
      };

      edit {
        title 'Edit me';
        title 'Second edit me';
        dbic_update {};
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
          { type   => 'Header',
            header => 'My list header',
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
          { type => 'CB',
            cb   => ignore(),
          },
        ],
      },
      { name   => 'pop',
        layout => [{title => 'My pop title', type => 'Title'}],
      },
      { name   => 'create',
        layout => [
          {valid => ignore(),    type => 'DBIC::Create'},
          {title => 'Create me', type => 'Title'}
        ],
      },
      { name   => 'edit',
        layout => [
          {title => 'Edit me',        type => 'Title'},
          {title => 'Second edit me', type => 'Title'},
          {valid => ignore(),         type => 'DBIC::Update'},
        ],
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

  is(scalar($action->widgets), 3, 'Has three widgets');
  my ($t, $h, $l) = $action->widgets;

  is($t->title, 'My list title', 'Title title is ok');
  is($t->id,    'w_1',           '... and ID matches');

  is($h->header, 'My list header', 'Header header is ok');
  is($h->id,     'w_2',            '... and ID matches');

  my $col_names = $l->col_names;
  is(scalar(@$col_names), 6, 'Number of columns is ok');
  cmp_deeply($col_names,
    [qw( id title slug created_at last_update_at is_visible )]);

  my $cols = $l->col_meta;
  cmp_deeply($cols->{id},    {linked  => 'view'},   'Meta for id ok');
  cmp_deeply($cols->{title}, {linked  => 'view'},   'Meta for title ok');
  cmp_deeply($cols->{slug},  {link_to => $slug_cb}, 'Meta for slug ok');
  cmp_deeply($cols->{is_visible}, {}, 'Meta for is_visible ok');

  is($l->id, 'w_3', 'List widget ID matches');

  ok(all_unique(map { $_->id } $action->widgets), 'All IDs are unique');
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

  ok(all_unique(map { $_->id } $action->widgets), 'All IDs are unique');
};


subtest 'View action' => sub {
  ok($m->has_action_for('view'), 'Our Ferdinand has a view action');
  my $action = $m->action_for('view');
  isa_ok($action, 'Ferdinand::Action', '... proper class for action');

  my @widgets = $action->widgets;
  is(scalar(@widgets), 4, 'Three widgets in this layout');
  is(ref($widgets[0]), 'Ferdinand::Widgets::Title',
    'Expected type for widget');
  is($widgets[0]->title, $title_cb, 'Title cb is ok');

  my $ctx;
  is(exception { $ctx = $m->render('view', {id => ['yuppii']}) },
    undef, "Render didn't die");

  is($ctx->stash->{title}, 'View for yuppii', 'Dynamic title as expected');
  is($ctx->stash->{item}, $ctx, 'dbic_item() called with the expected $_');
  is($ctx->stash->{set},  $ctx, 'dbic_set() called with the expected $_');
  is($ctx->stash->{cb_called}, $$, 'execute() called with the expected $_');

  ok(all_unique(map { $_->id } $action->widgets), 'All IDs are unique');
};


subtest 'Create action' => sub {
  ok($m->has_action_for('create'), 'Our Ferdinand has a create action');
  my $action = $m->action_for('create');
  isa_ok($action, 'Ferdinand::Action', '... proper class for action');

  my @widgets = $action->widgets;
  is(scalar(@widgets), 2, 'Two widgets in this layout');

  my ($c, $t) = @widgets;

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
  is(scalar(@widgets), 3, 'Two widget in this layout');

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
