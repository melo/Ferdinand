package Ferdinand::Action;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

with
  'Ferdinand::Roles::Setup',
  'Ferdinand::Roles::Renderer',
  'Ferdinand::Roles::WidgetContainer';

has 'name' => (isa => 'Str', is => 'ro', required => 1);

after setup_fields => method ($fields) { push @$fields, 'name' };


__PACKAGE__->meta->make_immutable;
1;
