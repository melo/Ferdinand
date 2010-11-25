package Ferdinand::Widgets::CB;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'cb' => (isa => 'CodeRef', is => 'ro', required => 1);


method setup_attrs ($class:, $attrs, $meta) {
  ## Remove known attributes
  for my $f (qw( cb )) {
    $attrs->{$f} = delete $meta->{$f} if exists $meta->{$f};
  }
}

method render_self ($ctx) {
  local $_ = $ctx;
  $self->cb->($self);
}


__PACKAGE__->meta->make_immutable;
1;
