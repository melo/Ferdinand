package Ferdinand::Roles::Renderer;

use Ferdinand::Setup 'role';
use Method::Signatures;

method render($ctx) {
  $self->render_self($ctx);
  $self->render_end($ctx);

  return $ctx;
}

sub render_self { }
sub render_end  { }

1;
