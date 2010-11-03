package Ferdinand::Action;
# ABSTRACT: a very cool module

use Ferdinand::Moose;
use namespace::clean -except => 'meta';

__PACKAGE__->meta->make_immutable;
1;
