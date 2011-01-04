package TDB::Result::A;

use strict;
use warnings;
use base 'DBIx::Class::Core';
use DateTime;

__PACKAGE__->table('a');

__PACKAGE__->add_columns(
  'id' => {
    data_type         => 'integer',
    is_nullable       => 0,
    is_auto_increment => 1,
  },

  'i_id' => {
    data_type   => 'integer',
    is_nullable => 0,
  },
  'name' => {
    data_type   => 'varchar',
    size        => 100,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  i => 'TDB::Result::I',
  {'foreign.id' => 'self.i_id'},
);

1;
