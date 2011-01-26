package Ferdinand::Widgets::CB;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'cb' => (isa => 'CodeRef', is => 'ro', required => 1);

after setup_fields => method ($fields) { push @$fields, 'cb' };


method render_self ($ctx) {
  local $_ = $ctx;
  $self->cb->($self);
}


__PACKAGE__->meta->make_immutable;
1;
