package Ferdinand::Widgets::DBIC::Source;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Ferdinand::Model::DBIC;
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'model' => (isa => 'Ferdinand::Model::DBIC', is => 'ro', required => 1);


after setup_attrs => method ($class:, $attrs, $meta, $sys, $stash) {
  my $source = delete $meta->{source};
  $source = $source->() if ref($source) eq 'CODE';

  $stash->{model} = $attrs->{model} =
    Ferdinand::Model::DBIC->new(source => $source);
};


after setup_check_self => method ($ctx) {
  $ctx->model($self->model);
};


method render_self ($ctx) {
  $ctx->model($self->model);
}


__PACKAGE__->meta->make_immutable;
1;
