package Ferdinand::Roles::ColumnSet;

use Ferdinand::Setup 'role';
use Method::Signatures;

requires 'setup_attrs';

has 'col_names' => (
  isa      => 'ArrayRef',
  is       => 'ro',
  required => 1,
);

has 'col_meta' => (
  isa      => 'HashRef',
  is       => 'ro',
  required => 1,
);


after setup_attrs => method ($class:, $attrs, $meta, $sys, $stash) {
  my $cols_spec = delete($meta->{columns}) || [];
  confess "Requires a 'columns' specification, "
    unless @$cols_spec;

  my $model = $stash->{model};

  my @names;
  my %meta;
  while (@$cols_spec) {
    my $name = shift @$cols_spec;
    my $info = ref($cols_spec->[0]) eq 'HASH' ? shift @$cols_spec : {};

    $info = $model->column_meta_fixup($name, $info) if $model;

    push @names, $name;
    $meta{$name} = $info;
  }

  $attrs->{col_names} = \@names;
  $attrs->{col_meta}  = \%meta;
};


1;
