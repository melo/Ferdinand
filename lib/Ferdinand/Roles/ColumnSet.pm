package Ferdinand::Roles::ColumnSet;

use Ferdinand::Setup 'role';
use Method::Signatures;

requires 'setup_attrs', 'setup_check_self';

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
    my $fn = my $name = shift @$cols_spec;
    my $info = ref($cols_spec->[0]) eq 'HASH' ? shift @$cols_spec : {};

    $fn   = delete $info->{field} if exists $info->{field};
    $name = delete $info->{as}    if exists $info->{as};
    $info = $model->column_meta_fixup($fn, $info) if $model;

    $info->{name}  = $name;
    $info->{field} = $fn;

    push @names, $name;
    $meta{$name} = $info;
  }

  $attrs->{col_names} = \@names;
  $attrs->{col_meta}  = \%meta;
};

after setup_check_self => method ($ctx) {
  my $model = $ctx->model;
  my $meta  = $self->col_meta;

  for my $f (keys %$meta) {
    $model->set_field_meta($f => $meta->{$f});
  }
};

method _get_columns_from_item ($ctx, $item) {
  my $cols = $self->col_names;

  $item = $ctx->item unless $item;

  my %html;
  for my $col (@$cols) {
    $html{$col} = $ctx->render_field_read(
      field => $col,
      item  => $item,
    );
  }
  my $id = $ctx->id_for_item($item);
  $html{__ID} = $id if defined $id;

  return \%html;
}


1;
