package Ferdinand::Widgets::Header;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Ferdinand::Utils 'ghtml';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'header' => (isa => 'Str|CodeRef', is => 'ro', required => 1);

after setup_fields => method ($fields) { push @$fields, 'header' };


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
