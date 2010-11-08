package Ferdinand::Roles::ColumnSet;

use Ferdinand::Setup 'role';
use Method::Signatures;

requires 'setup_attrs';

has 'column_names' => (
  isa      => 'ArrayRef',
  is       => 'ro',
  required => 1,
);

has 'columns' => (
  isa      => 'HashRef',
  is       => 'ro',
  required => 1,
);


after setup_attrs => sub {
  my ($class, $attrs, $impl, $meta) = @_;

  my $col_spec = delete($meta->{columns}) || [];
  confess "Requires a 'columns' specification, "
    unless @$col_spec;

  my @col_order;
  my %col_meta;
  while (@$col_spec) {
    my $name = shift @$col_spec;
    my $info = ref($col_spec->[0]) eq 'HASH' ? shift @$col_spec : {};

    push @col_order, $name;
    $col_meta{$name} = $info;

    $impl->column_meta_fixup($name, $info);
  }

  $attrs->{column_names} = \@col_order;
  $attrs->{columns}      = \%col_meta;
};


1;
