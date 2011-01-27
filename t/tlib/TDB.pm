package TDB;

use strict;
use warnings;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces();

sub test_deploy {
  my $class = shift;

  my $db = $class->connect('dbi:SQLite::memory:');
  $db->deploy({});

  $db->populate(
    'I',
    [ [qw/id title slug body published_at visible html/],
      [ 1, 'Title 1 & me', 'title_1', '
testing
=======

 * first
 * second
 * third

', '2010-10-10 10:10:10', 'V', '
<p>text</p>
'
      ],
      [ 2, 'Title 2', 'title_2', '
more stuff
----------

 1. one
 2. two
 3. three

', '2010-11-11 11:11:11', 'H', '
<p>text</p>
'
      ],
    ]
  );

  my $rs = $db->resultset('I');
  while (my $i = $rs->next) {
    $i->create_related(a => {name => $i->title . ' - Mini Me'});
  }

  return $db;
}

1;
