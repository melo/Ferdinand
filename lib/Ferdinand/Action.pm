package Ferdinand::Action;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

with
  'Ferdinand::Roles::Setup',
  'Ferdinand::Roles::Renderer',
  'Ferdinand::Roles::WidgetContainer';

has 'name' => (isa => 'Str', is => 'ro', required => 1);


method setup_attrs ($class:, $attrs, $meta) {
  ## Remove known attributes
  for my $f (qw( name )) {
    $attrs->{$f} = delete $meta->{$f} if exists $meta->{$f};
  }
}


__PACKAGE__->meta->make_immutable;
1;
