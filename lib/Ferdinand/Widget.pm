package Ferdinand::Widget;

use Ferdinand::Setup 'class';

with
  'Ferdinand::Roles::Setup',
  'Ferdinand::Roles::Renderer';


__PACKAGE__->meta->make_immutable;
1;
