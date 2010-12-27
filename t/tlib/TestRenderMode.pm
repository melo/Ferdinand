package TestRenderMode;

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::RenderPerMode';

method render_self_read ($ctx) {
  $ctx->buffer('reader');
}

method render_self_write ($ctx) {
  $ctx->buffer('writer');
}

method render_self_setup ($ctx) {
  $ctx->buffer('setup');
}


__PACKAGE__->meta->make_immutable;
1;
