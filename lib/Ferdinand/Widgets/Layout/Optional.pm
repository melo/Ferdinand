package Ferdinand::Widgets::Layout::Optional;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widgets::Layout';

has 'skip' => (isa => 'Str', is => 'ro');

after setup_fields => method ($fields) {push @$fields, 'skip'};

after setup_attrs => method ($class :, $attrs) {$attrs->{on_demand} = 1};


after render_self => method ($ctx) {
  my $skip = $self->skip || '';
    return if $skip eq 'item' && !defined $ctx->item;
  return   if $skip eq 'set'  && $ctx->set->count == 0;

  $self->render_widgets($ctx);
};


__PACKAGE__->meta->make_immutable;
1;
