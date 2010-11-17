package Ferdinand::Widgets::Layout;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::WidgetContainer';


__PACKAGE__->meta->make_immutable;
1;
