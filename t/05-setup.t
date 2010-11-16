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


my $title_cb = sub { join(' ', 'View for', $_[1]->id) };
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
        layout => [{title => $title_cb, type => 'Title'}],
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

TODO: {
    local $TODO = 'columns() not implemented yet';

    my $cols = $l->col_meta;
    cmp_deeply($cols->{id},
      {linked => 'view', label => 'Id'});
    cmp_deeply($cols->{is_visible},
      {label => 'Is Visible', cls_list => [], cls_list_html => ''});
  }
};

done_testing();
