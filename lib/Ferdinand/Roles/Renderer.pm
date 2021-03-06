package Ferdinand::Roles::Renderer;

use Ferdinand::Setup 'role';
use Method::Signatures;

method render ($ctx) {
  my $cleanup_widget = $ctx->overlay(widget => $self);

  my $cleanup_guard = $self->render_begin($ctx);
  $self->render_self($ctx);
  $self->render_end($ctx);

  return $ctx;
}

sub render_begin { }
sub render_end   { }

method render_self ($ctx) {
  $self->render_per_mode($ctx);
}

method render_per_mode ($ctx) {
  my $m = $ctx->mode;
  return $self->render_self_read(@_)  if $m eq 'view'   || $m eq 'list';
  return $self->render_self_write(@_) if $m eq 'create' || $m eq 'create_do';
  return $self->render_self_write(@_) if $m eq 'edit'   || $m eq 'edit_do';
};

sub render_self_read  { }
sub render_self_write { }

1;
