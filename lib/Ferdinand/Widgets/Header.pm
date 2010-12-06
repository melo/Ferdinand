package Ferdinand::Widgets::Header;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Ferdinand::Utils 'ghtml';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'header' => (isa => 'Str|CodeRef', is => 'ro', required => 1);


method setup_attrs ($class:, $attrs, $meta) {
  ## Remove known attributes
  for my $f (qw( header )) {
    $attrs->{$f} = delete $meta->{$f} if exists $meta->{$f};
  }
}

method render_self ($ctx) {
  my $header = $self->header;
  if (ref($header) eq 'CODE') {
    local $_ = $ctx;
    $header = $header->($self, $ctx);
  }

  $ctx->buffer(ghtml()->h1($header));
}


__PACKAGE__->meta->make_immutable;
1;
