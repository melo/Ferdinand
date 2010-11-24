package Ferdinand::Widget;

use Ferdinand::Setup 'class';

with
  'Ferdinand::Roles::Setup',
  'Ferdinand::Roles::Renderer';

has 'id' => ( isa => 'Str', is  => 'ro', required => 1);


__PACKAGE__->meta->make_immutable;
1;
