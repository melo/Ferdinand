package Ferdinand::Widget;

use Ferdinand::Setup 'class';
use Method::Signatures;

with
  'Ferdinand::Roles::Setup',
  'Ferdinand::Roles::Renderer';

has 'id' => ( isa => 'Str', is  => 'ro', required => 1);

method render_begin ($ctx) {
  return $ctx->overlay(widget => $self);
}


__PACKAGE__->meta->make_immutable;
1;
