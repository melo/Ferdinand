package Ferdinand::Widgets::State;

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw(ghtml);
use Method::Signatures;
use namespace::clean -except => 'meta';

extends 'Ferdinand::Widget';

has 'cb' => (
  is      => 'ro',
  isa     => 'CodeRef',
);

after setup_fields => method ($fields) {push @$fields, qw(cb)};


method render_self_write ($ctx) {
  my $cb = $self->cb;
  return unless $cb;

  local $_ = $ctx;
  my $state = $cb->($self);

  while (my ($k, $v) = each %$state) {
    $ctx->buffer(ghtml()->input({type => 'hidden', name => $k, value => $v}));
  }
}


__PACKAGE__->meta->make_immutable;
1;
