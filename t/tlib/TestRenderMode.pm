package TestRenderMode;

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

method render_self_read ($ctx) {
  $ctx->buffer('reader');
}

method render_self_write ($ctx) {
  $ctx->buffer('writer');
}


__PACKAGE__->meta->make_immutable;
1;
