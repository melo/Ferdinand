package Ferdinand::Widgets::DBIC::Set;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'set' => (isa => 'CodeRef', is => 'ro', required => 1);


after setup_attrs => method ($class:, $attrs, $meta, $sys, $stash) {
  for my $f (qw( set )) {
    $attrs->{$f} = delete $meta->{$f} if exists $meta->{$f};
  }
};

method render_self ($ctx) {
  local $_ = $ctx;
  my $rs = $self->set->($self, $ctx);
  $ctx->set($rs) if $rs;
}


__PACKAGE__->meta->make_immutable;
1;
