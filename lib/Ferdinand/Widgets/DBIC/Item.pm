package Ferdinand::Widgets::DBIC::Item;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'item' => (isa => 'CodeRef', is => 'ro', required => 1);


method setup_attrs ($class:, $attrs, $meta) {
  for my $f (qw( item )) {
    $attrs->{$f} = delete $meta->{$f} if exists $meta->{$f};
  }
}

method render_self ($ctx) {
  $ctx->item($self->item->($self, $ctx));
}


__PACKAGE__->meta->make_immutable;
1;
