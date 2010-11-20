package TDB;

use strict;
use warnings;
use base 'DBIx::Class::Schema';
use File::Temp;

__PACKAGE__->load_namespaces();

sub test_deploy {
  my $class = shift;

  my $fh = File::Temp->new;
  my $db = $class->connect('dbi:SQLite::memory:');
  $db->deploy({});

  $db->populate(
    'I',
    [ [qw/id title slug published_at visible/],
      [1, 'Title 1 & me', 'title_1', '2010-10-10 10:10:10', 'V'],
      [2, 'Title 2',      'title_2', '2010-11-11 11:11:11', 'H'],
    ]
  );

  return ($db, $fh);
}

1;
