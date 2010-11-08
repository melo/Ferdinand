package Ferdinand::Utils;

use Ferdinand::Setup 'library';
use Tenjin;
use XML::Generator;
use Carp 'confess';

our @EXPORT_OK = qw(
  new_context
  read_data_files get_data_files
  render_template
  ghtml ehtml
);


sub new_context {
  my %ctx = %{(shift)};

  while (@_) {
    my ($k, $v) = splice(@_, 0, 2);

    if (defined $v) { $ctx{$k} = $v }
    else            { delete $ctx{$k} }
  }

  return \%ctx;
}

sub get_data_files {
  my ($class) = @_;
  $class ||= caller;

  my $cache = "${class}::Ferdinand_Utils_get_data_files";

  no strict 'refs';
  return $$cache if $$cache;
  return $$cache = read_data_files($class);
}

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

sub render_template {
  my ($tmpl, $data, $class) = @_;

  if (ref $tmpl) {
    $tmpl = $$tmpl;
  }
  else {
    $class ||= caller();
    my $files = get_data_files($class);
    confess "Template '$tmpl' not found in class '$class', "
      unless exists $files->{$tmpl};

    $tmpl = $files->{$tmpl};
  }

  local $Tenjin::USE_STRICT = 1;
  my $engine = Tenjin::Engine->new({cache => 0});
  return $engine->render(\$tmpl, $data);
}

sub ghtml {
  return XML::Generator->new(':pretty');
}

sub ehtml {
  my ($value) = @_;

  XML::Generator::util::escape($value,
    XML::Generator::util::ESCAPE_ALWAYS()
      | XML::Generator::util::ESCAPE_EVEN_ENTITIES()
      | XML::Generator::util::ESCAPE_GT());

  return $value;
}

1;
