package Ferdinand::Widgets::DBIC::Create;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'valid' => (
  isa     => 'CodeRef',
  is      => 'ro',
  default => sub {
    sub { }
  },
);


method setup_attrs ($class:, $attrs, $meta) {
  for my $f (qw( valid )) {
    $attrs->{$f} = delete $meta->{$f} if exists $meta->{$f};
  }
}

method render_self ($ctx) {
  local $_ = $ctx;
  $self->valid->($self);
}


__PACKAGE__->meta->make_immutable;
1;
