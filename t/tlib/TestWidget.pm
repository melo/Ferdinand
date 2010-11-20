package TestWidget;

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

method render_self ($ctx) {
  $ctx->stash->{titi} = ref($self) . " $$";
}


__PACKAGE__->meta->make_immutable;
1;
