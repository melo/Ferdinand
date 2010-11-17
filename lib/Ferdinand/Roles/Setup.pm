package Ferdinand::Roles::Setup;

use Ferdinand::Setup 'role';
use Method::Signatures;

method setup ($class:, $meta, $sys?, $stash = {}) {
  my %attrs;
  $class->setup_attrs(\%attrs, $meta, ($sys || $class), $stash);

  return $class->new(%attrs);
}

method setup_attrs ($class:, $attrs, $meta, $sys, $stash) {}


1;
