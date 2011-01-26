package Ferdinand::Widgets::Title;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'title' => (isa => 'Str|CodeRef', is => 'ro', required => 1);

after setup_fields => method ($fields) { push @$fields, 'title' };


method render_self ($ctx) {
  my $title = $self->title;
  if (ref($title) eq 'CODE') {
    local $_ = $ctx;
    $title = $title->($ctx->item) ;
  }
  $ctx->stash(title => $title) if $title;
}


__PACKAGE__->meta->make_immutable;
1;
