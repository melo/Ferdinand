package Ferdinand::Widgets::DBIC::Item;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'item' => (isa => 'CodeRef', is => 'ro', required => 1);

after setup_fields => method ($fields) { push @$fields, 'item' };


method render_self ($ctx) {
  local $_ = $ctx;
  my $item = $self->item->($self, $ctx);

  confess("Item not found") unless $item;
  $ctx->item($item);
}


__PACKAGE__->meta->make_immutable;
1;
