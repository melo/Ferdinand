package Ferdinand::Widgets::Layout;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::WidgetContainer';

has 'overlay' => (isa => 'HashRef', is => 'ro');

after setup_attrs => method($class:, $attrs, $meta) {
  $attrs->{overlay} = delete $meta->{overlay}
    if exists $meta->{overlay};
};

method render_begin ($ctx) {
  my $o = $self->overlay;

  return unless $o;
  return $ctx->overlay(%$o);
}


__PACKAGE__->meta->make_immutable;
1;
