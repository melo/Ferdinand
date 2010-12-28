package Ferdinand::Widget;

use Ferdinand::Setup 'class';
use Method::Signatures;

with
  'Ferdinand::Roles::Setup',
  'Ferdinand::Roles::Renderer';

method render_begin ($ctx) {
  return $ctx->overlay(widget => $self);
}


__PACKAGE__->meta->make_immutable;
1;
