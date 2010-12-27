package Ferdinand::Roles::RenderPerMode;

use Ferdinand::Setup 'role';

after render_self => sub {
  my $self = shift;

  my $m = $_[0]->mode;
  return $self->render_self_read(@_)  if $m eq 'view'   || $m eq 'list';
  return $self->render_self_write(@_) if $m eq 'create' || $m eq 'create_do';
  return $self->render_self_setup(@_) if $m eq 'setup';
};

sub render_self_read  { }
sub render_self_write { }
sub render_self_setup { }

1;
