package Ferdinand::Roles::RenderPerMode;

use Ferdinand::Setup 'role';

after render_self => sub {
  my $self = shift;

  my $m = $_[0]->mode;
  $self->render_self_read(@_) if $m eq 'view';
  $self->render_self_write(@_) if $m eq 'create' || $m eq 'create_do';
};

sub render_self_read  { }
sub render_self_write { }

1;
