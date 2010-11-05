package Sample;

use strict;
use warnings;
use Ferdinand::Utils 'read_data_files', 'get_data_files', 'render_template';

sub load_them {
  return read_data_files();
}

sub cache_them {
  return get_data_files();
}

sub render { shift; return render_template(@_) }

1;

__DATA__

@@ file1.txt
This is my file.

There are many others like it, but this one is mine.

@@ list.pltj
<?pl #@ARGS title, items ?>
title [= $title =]
<?pl for my $i (@$items) { ?>
  [= $i->{rank} =]. [= $i->{name} =]
<?pl } ?>

@@ file2.html
We love HTML5!

__END__
This is not part of that...
