package TestRenderField;

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::ColumnSet';

method render_self ($ctx) {
  my $s = $ctx->stash;
  $s->{col_names} = $self->col_names;
  $s->{col_meta}  = $self->col_meta;
}


__PACKAGE__->meta->make_immutable;
1;
