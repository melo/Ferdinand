#!perl

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MockObject;
use Ferdinand;

my $source = bless {}, 'DBIx::Class::ResultSource';
{
  no strict 'refs';
  *{'DBIx::Class::ResultSource::column_info'} = sub { {} };
}

my %meta = (
  source => $source,

  list => {
    title   => 'Articles',
    columns => [
      id    => {linked => 'view'},
      title => {linked => 'view'},

      slug => {
        link_to => sub {
          my ($c, $i) = @_;

          return 'http://example.com/items/' . $i->slug;
        },
      },

      'created_at',
      'last_update_at',
      'is_visible',
    ],
  },
);

my $f;
is(exception { $f = Ferdinand->setup(\%meta) },
  undef, 'Setup of Ferdinand ok');

isa_ok($f, 'Ferdinand::Impl', '... expected base class');
isa_ok($f->source, 'DBIx::Class::ResultSource');

subtest 'List action', sub {
  ok($f->has_action_for('list'), 'Our Ferdinand has a list action');
  my $action = $f->action_for('list');
  isnt($action, undef, '... and seem to have it');
  isa_ok($action, 'Ferdinand::Actions::List');

  is($action->title, 'Articles', 'List title ok');

  my $col_names = $action->column_names;
  is(scalar(@$col_names), 6, 'Number of columns is ok');
  cmp_deeply($col_names,
    [qw( id title slug created_at last_update_at is_visible )]);

  my $cols = $action->columns;
  cmp_deeply($cols->{id}, {linked => 'view', label => 'Id'});
  cmp_deeply($cols->{is_visible}, {label => 'Is Visible'});
};

done_testing();
