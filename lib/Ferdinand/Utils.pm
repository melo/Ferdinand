package Ferdinand::Utils;

use strict;
use warnings;
use parent 'Exporter';

our @EXPORT_OK = qw( read_data_files );

sub read_data_files {
  my ($class) = @_;
  $class ||= caller;

  # Handle
  my $d = do { no strict 'refs'; \*{"$class\::DATA"} };

  # Shortcut
  return unless fileno $d;

  # Reset
  seek $d, 0, 0;

  # Slurp
  my $content = do { local $/; <$d> };

  # Ignore everything before __DATA__ (windows will seek to start of file)
  $content =~ s/^.*\n__DATA__\n/\n/s;

  # Ignore everything after __END__
  $content =~ s/\n__END__\n.*$/\n/s;

  # Split
  my @data = split /^@@\s+(.+)\s*\r?\n/m, $content;

  # Remove split garbage
  shift @data;

  # Find data
  my %all;
  while (@data) {
    my ($name, $content) = splice @data, 0, 2;

    $all{$name} = $content;
  }

  return \%all;
}

1;
