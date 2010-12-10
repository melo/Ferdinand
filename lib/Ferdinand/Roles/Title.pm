package Ferdinand::Roles::Title;

use Ferdinand::Setup 'role';
use Ferdinand::Utils 'ghtml';
use Method::Signatures;

requires 'setup_attrs';

has 'title' => (
  is  => 'bare',
  isa => 'CodeRef|Str',
);

after setup_attrs => sub {
  my ($class, $attrs, $meta) = @_;
  $attrs->{title} = delete $meta->{title} if exists $meta->{title};
};

method title ($ctx) {
  my $t = $self->{title};
  return $t unless ref $t;

  local $_ = $ctx;
  return $t->($self);
}

method render_title ($ctx) {
  return unless my $t = $self->title($ctx);
  return ghtml()->h1($t);
}

1;
