package Ferdinand::Context;

use Ferdinand::Setup 'class';
use Method::Signatures;

has 'impl'        => (isa => 'Ferdinand::Impl',   is => 'ro', required => 1);
has 'action'      => (isa => 'Ferdinand::Action', is => 'ro', required => 1);
has 'action_name' => (isa => 'Str',               is => 'ro', required => 1);
has 'widget'      => (isa => 'Ferdinand::Widget', is => 'rw');

has 'buffer' => (
  isa     => 'Str',
  is      => 'ro',
  default => '',
  reader  => '_buffer',
  clearer => 'clear_buffer',
);

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
  my $attrs  = ref($_[0]) ? shift : {};
  my $fields = $self->{fields};
  my $ctx    = ref($self)->new(%$self, %$attrs, fields => {%$fields});
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

method page_title () {
  my $title = $self->action->title;
  $title = $title->($self, @_) if ref $title;

  return $title;
}


#################
# Field shortcuts

method row ($row?) {
  my $f = $self->{fields};

  $f->{row} = $row if @_;
  return $f->{row} if exists $f->{row};
  return;
}

method rows ($rows?) {
  my $f = $self->{fields};

  $f->{rows} = $rows if @_;
  return $f->{rows} if exists $f->{rows};
  return;
}

method id () {
  return $self->{fields}{id} if exists $self->{fields}{id};
  return;
}

method params () {
  return $self->{fields}{params} if exists $self->{fields}{params};
  return;
}

method uri_helper () {
  return $self->{fields}{uri_helper}->($self, @_)
    if exists $self->{fields}{uri_helper};
  return;
}


###################
# Buffer management

method buffer () {
  local $" = '';
  $self->{buffer} .= "@_";
}


#######
# Utils

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
