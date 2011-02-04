package Ferdinand::Roles::Title;

use Ferdinand::Setup 'role';
use Ferdinand::Utils qw(ghtml hash_merge);
use Method::Signatures;

requires 'setup_attrs';

has 'title' => (
  is  => 'bare',
  isa => 'CodeRef|Str',
);

has 'title_class' => (
  is      => 'ro',
  isa     => 'Str',
  default => 'w_title',
);

after setup_fields => method($fields) {push @$fields, qw(title title_class)};


method title ($ctx) {
  my $t = $self->{title};
  return $t unless ref $t;

  local $_ = $ctx;
  return $t->($ctx->item);
}

method render_title ($ctx, $args = {}) {
  return unless my $t = $self->title($ctx);

  $args = hash_merge({}, class => $self->title_class, %$args);

  return ghtml()->h1($args, $t);
}

1;
