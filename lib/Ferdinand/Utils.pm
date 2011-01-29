package Ferdinand::Utils;

use Ferdinand::Setup 'library';
use Tenjin;
use Encode;
use XML::Generator;
use Class::MOP ();
use Carp 'confess';
use Scalar::Util 'blessed';

our @EXPORT_OK = qw(
  empty
  load_class load_widget
  read_data_files get_data_files
  render_template
  ghtml ehtml
  hash_merge hash_select hash_grep hash_cleanup hash_decode
  expand_structure parse_structured_key select_structure
  walk_structure find_structure serialize_structure
  dbicset_as_options
);


sub empty {
  return 1 unless defined $_[0];
  return 1 unless length $_[0];
  return 0;
}

sub load_class {
  my ($class) = @_;

  Class::MOP::load_class($class)
    or confess("Could not load class '$class': $@, ");

  return $class;
}

sub load_widget {
  my ($name) = @_;

  $name = "Ferdinand::Widgets::$name"
    unless $name =~ s/^\+//;

  return load_class($name);
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
  return XML::Generator->new(':pretty', escape => 'unescaped');
}

sub ehtml {
  my ($value) = @_;

  XML::Generator::util::escape($value,
    XML::Generator::util::ESCAPE_ALWAYS()
      | XML::Generator::util::ESCAPE_EVEN_ENTITIES()
      | XML::Generator::util::ESCAPE_GT());

  return $value;
}

=function hash_merge

Accepts a target hashref and a list of key/value pairs. For each pair,
if the value is defined, sets the target key to the new value. If the
value is undefined, removes the key from the target.

Returns nothing, the target hashref is modified in place.

    my $target = { a => 1, c => 3 };
    hash_merge($target, a => 2, b => 2, c => undef);
    ## $target is now { a => 2, b => 2 }

=cut

sub hash_merge {
  my $h = shift;

  while (@_) {
    my ($k, $v) = splice(@_, 0, 2);

    if (defined $v) { $h->{$k} = $v }
    else            { delete $h->{$k} }
  }

  return $h;
}

sub hash_select {
  my $h = shift;
  my %s;

  for my $k (@_) {
    $s{$k} = $h->{$k} if exists $h->{$k};
  }

  return \%s;
}

sub hash_grep (&$) {
  my ($cb, $in) = @_;
  my %out;

  for my $k (keys %$in) {
    my $v = $in->{$k};
    local $_ = $k;
    next unless $cb->($v);

    $out{$k} = $v;
  }

  return %out if wantarray;
  return \%out;
}

sub hash_cleanup {
  my ($h, @fields) = @_;
  @fields = keys %$h unless @fields;

  for my $k (@fields) {
    next unless exists $h->{$k};

    my $v = $h->{$k};
    if (!defined $v) {
      delete $h->{$k};
    }
    elsif (ref($v) eq 'HASH') {
      hash_cleanup($v, keys %$v);
      delete $h->{$k} unless %$v;
    }
  }

  return $h;
}

sub hash_decode {
  my ($hash, $charset) = @_;
  $charset = 'utf8' unless $charset;

  my %decoded;
  while (my ($k, $v) = each %$hash) {
    $decoded{$k} = Encode::decode($charset, $v);
  }

  return \%decoded;
}


=function expand_structure

Given a HashRef with key => values pairs, expand each key into the proper Perl structure.

The encoding is simple:

 * key: { key => value };
 * key1.key2: { key1 => { key2 => value }}
 * key1.key2[0]: { key1 => { key2 => [value] }}
 * key1.key2[1]: { key1 => { key2 => [undef, value] }}
 * key1.key2[1].key3: { key1 => { key2 => [undef, { key3 => value}] }}

=cut

sub expand_structure {
  my ($in) = @_;
  my %out;

  for my $src (keys %$in) {
    my (@path) = parse_structured_key($src);

    my $n;
    my $s   = \%out;
    my $set = sub {
      if   (ref($s) eq 'HASH') { $s = $s->{$n} ||= $_[0] }
      else                     { $s = $s->[$n] ||= $_[0] }
    };

    $n = shift @path;
    while (@path) {
      $set->(ref($path[0]) ? [] : {});
      $n = shift @path;
      $n = $$n if ref $n;
    }

    $set->($in->{$src});
  }

  return \%out;
}

sub serialize_structure {
  my ($in) = @_;
  return unless defined $in;

  my $t = ref($in);
  return $in unless $t;

  return _serialize_hash($in)  if $t eq 'HASH';
  return _serialize_array($in) if $t eq 'ARRAY';

  confess("Reference of type '$t' is not supported,");
}

sub _serialize_hash {
  my ($in) = @_;
  my %map;

  for my $k (keys %$in) {
    my $v = $in->{$k};
    next unless defined $v;

    my $t = ref($v);
    if (!$t) {
      $map{$k} = $v;
      next;
    }

    my $data = serialize_structure($v);
    if ($t eq 'HASH') {
      while (my ($sk, $sv) = each %$data) {
        $map{"$k.$sk"} = $sv;
      }
    }
    else {
      my $c = 0;
      for my $i (@$data) {
        while (my ($sk, $sv) = each %$i) {
          $map{"${k}[${c}].$sk"} = $sv;
        }
        $c++;
      }
    }
  }

  return \%map;
}

sub _serialize_array {
  my ($in) = @_;
  my @out;

  for my $i (@$in) {
    push @out, serialize_structure($i);
  }

  return \@out;
}

sub parse_structured_key {
  return
    map { /^(.+)\[(\d+)\]$/ ? ($1, \(my $i = $2)) : $_ } split(/[.]/, $_[0]);
}

sub find_structure {
  my ($in, $k) = @_;

  my (@path) = parse_structured_key($k);

  my $s = $in;
  while (@path) {
    my $n = shift @path;

    unless (defined($s) && ref($s) eq 'HASH' && exists $s->{$n}) {
      $s = undef;
      last;
    }

    $s = $s->{$n};
  }

  return $s;
}

sub select_structure {
  my $in = shift;

  my %values;
KEY: for my $k (@_) {
    my (@path) = parse_structured_key($k);

    my $s = $in;
    while (@path) {
      my $n = shift @path;

      next KEY unless defined($s) && ref($s) eq 'HASH' && exists $s->{$n};

      $s = $s->{$n};
    }

    $values{$k} = $s;
  }

  return expand_structure(\%values);
}

sub walk_structure {
  my ($item, $field) = @_;

  my @path = parse_structured_key($field);

  my $top;
  while ($item && @path) {
    my $name = $field = shift @path;
    $top = $item;
    confess("FATAL: no support for list fields, ") if ref $name;

    if (blessed($item) && $item->can($name)) { $item = $item->$name() }
    elsif (ref($item) eq 'HASH') { $item = $item->{$name} }
    else                         { $item = undef }
  }

  return [undef, pop(@path), undef] if @path;
  return [$top, $field, $item];
}


##############
# DBIC helpers

sub dbicset_as_options ($$;$) {
  my ($rs, $field, $ctx) = @_;

  my $get_field =
    $ctx
    ? sub { $ctx->field_value_str(item => $_[0], field => $_[1])->[3] }
    : sub { my ($i, $f) = @_; $i->$f() };
  my $get_text = sub { $get_field->(@_) || "<no $_[1]>" };

  my @options;
  my $fmt = ref($field) ? shift @$field : undef;
  while (my $item = $rs->next) {
    my $text;
    if ($fmt) {
      $text = sprintf($fmt, map { $get_text->($item, $_) } @$field);
    }
    else {
      $text = $get_text->($item, $field);
    }

    push @options, {id => $item->id, text => $text};
  }

  return \@options;
}

1;
