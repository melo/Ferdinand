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
    [ [qw/id title slug body published_at visible/],
      [ 1, 'Title 1 & me', 'title_1', '
testing
=======

 * first
 * second
 * third

', '2010-10-10 10:10:10', 'V'
      ],
      [ 2, 'Title 2', 'title_2', '
more stuff
----------

 1. one
 2. two
 3. three

', '2010-11-11 11:11:11', 'H'
      ],
    ]
  );

  return ($db, $fh);
}

1;
