package Sample;

use strict;
use warnings;
use Ferdinand::Utils 'read_data_files';

sub load_them {
  return read_data_files();
}

1;

__DATA__

@@ file1.txt
This is my file.

There are many others like it, but this one is mine.

@@ file2.html
We love HTML5!

__END__
This is not part of that...
