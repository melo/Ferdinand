package Ferdinand::Roles::Setup;

use Ferdinand::Setup 'role';
use Method::Signatures;

has 'id' => (
  isa => 'Str',
  is  => 'ro',
  required => 1
);

method setup ($class:, $meta, $sys?, $stash = {}) {
  my %attrs;
  $class->setup_attrs(\%attrs, $meta, ($sys || $class), $stash);
  $attrs{id} = 'w_' . ++$stash->{widget_ids} unless exists $attrs{id};

  my $self = $class->new(%attrs);
  $self->setup_done($stash);

  return $self;
}

method setup_attrs ($class:, $attrs, $meta, $sys, $stash) {}
method setup_done ($stash) {}

1;
