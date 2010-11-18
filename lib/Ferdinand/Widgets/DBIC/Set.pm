package Ferdinand::Widgets::DBIC::Set;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'set' => (isa => 'CodeRef', is => 'ro', required => 1);


method setup_attrs ($class:, $attrs, $meta) {
  for my $f (qw( set )) {
    $attrs->{$f} = delete $meta->{$f} if exists $meta->{$f};
  }
}

method render_self ($ctx) {
  $ctx->set($self->set->($self, $ctx));
}


__PACKAGE__->meta->make_immutable;
1;
