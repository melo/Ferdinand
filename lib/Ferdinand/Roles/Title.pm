package Ferdinand::Roles::Title;

use Ferdinand::Setup 'role';
use Ferdinand::Utils 'ghtml';
use Method::Signatures;

requires 'setup_attrs';

has 'title' => (
  is  => 'bare',
  isa => 'CodeRef|Str',
);

after setup_fields => method ($fields) { push @$fields, 'title' };


method title ($ctx) {
  my $t = $self->{title};
  return $t unless ref $t;

  local $_ = $ctx;
  return $t->($ctx->item);
}

method render_title ($ctx, $args = {}) {
  return unless my $t = $self->title($ctx);
  return ghtml()->h1($args, $t);
}

1;
