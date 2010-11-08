package Ferdinand::Context;

use Ferdinand::Setup 'class';
use Method::Signatures;

has 'impl'   => ( isa => 'Ferdinand::Impl',   is  => 'ro', required => 1);
has 'action' => ( isa => 'Ferdinand::Action', is  => 'ro', required => 1);
has 'widget' => ( isa => 'Ferdinand::Widget', is  => 'rw');

has 'stash' => (
  isa     => 'HashRef',
  is      => 'ro',
  default => sub { {} },
  reader  => '_stash',
);

has 'fields' => (
  isa     => 'HashRef',
  is      => 'ro',
  default => sub { {} },
  reader  => '_fields',
);


method clone () {
  my $fields = $self->{fields};
  my $ctx = ref($self)->new(%$self, fields => {%$fields});
  $ctx->fields(@_);

  return $ctx;
}

method fields () {
  my $f = $self->{fields};
  _merge($f, @_) if @_;

  return $f;
}

method stash () {
  my $s = $self->{stash};
  _merge($s, @_) if @_;

  return $s;
}

sub _merge {
  my $h = shift;

  while (@_) {
    my ($k, $v) = splice(@_, 0, 2);

    if (defined $v) { $h->{$k} = $v }
    else            { delete $h->{$k} }
  }

  return;
}


__PACKAGE__->meta->make_immutable;
1;
