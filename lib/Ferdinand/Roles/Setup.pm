package Ferdinand::Roles::Setup;

use Ferdinand::Setup 'role';
use Method::Signatures;

method setup ($class:, $meta, $sys?) {
  my %attrs;
  $class->setup_attrs(\%attrs, $meta, $sys);

  return $class->new(%attrs);
}

method setup_attrs ($class:, $attrs, $meta, $sys?) {}


1;
