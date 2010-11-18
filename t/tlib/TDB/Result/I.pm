package TDB::Result::I;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('i');

__PACKAGE__->add_columns(
  'id' => {
    data_type         => 'integer',
    is_nullable       => 0,
    is_auto_increment => 1,
  },

  'title' => {
    data_type => 'varchar',
    size      => 100,
  },
  'slug' => {
    data_type   => 'varchar',
    size        => 100,
    is_nullable => 0,
  },

  'published_at' => {
    data_type   => 'date',
    is_nullable => 0,
    extra       => {
      formatter => sub   { $_->dmy('/') },
      classes   => {list => "{sorter: 'eu_date'}"},
    },
  },
  'visible' => {
    data_type   => 'char',
    size        => 1,
    is_nullable => 0,
    default     => 'H'
  },
);

__PACKAGE__->set_primary_key('id');

1;
