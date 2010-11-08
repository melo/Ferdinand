package Ferdinand::Roles::Setup;

use Ferdinand::Setup 'role';
use Method::Signatures;

method setup ($class:) {
  $class->setup_attrs(\my %attrs, @_);
  return $class->new(%attrs);
}

method setup_attrs ($class:, $attrs, $impl, $meta) {}


1;


