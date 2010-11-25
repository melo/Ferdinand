package Ferdinand::Roles::Renderer;

use Ferdinand::Setup 'role';
use Method::Signatures;

method render ($ctx) {
  my $cleanup_guard = $self->render_begin($ctx);
  $self->render_self($ctx);
  $self->render_end($ctx);

  return $ctx;
}

sub render_begin { }
sub render_self  { }
sub render_end   { }

1;
