package Ferdinand::Context;

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw( hash_merge );
use Ferdinand::Form;
use Guard 'guard';
use Method::Signatures;

#################
# Main attributes

has 'map' => (isa => 'Ferdinand::Map', is => 'ro');
has 'action' => (isa => 'Ferdinand::Action', is => 'ro');

has 'widget' => (isa => 'Ferdinand::Widget', is => 'rw');

has 'params' => (isa => 'HashRef', is => 'ro', default => sub { {} });

has 'mode' => (isa => 'Str', is => 'ro', default => 'view');

has 'action_uri' => (isa => 'URI', is => 'ro');


##########################
# Clone/overlay a context

has 'parent' => (isa => 'Ferdinand::Context', is => 'ro');

method clone () {
  return ref($self)->new(%$self, @_, buffer => '', parent => $self);
}

method DEMOLISH () {
  my $p = $self->parent;
  return unless $p;

  my $b = $self->buffer;
  return unless length($b);

  $p->buffer($b);
}

method overlay () {
  my @saved;
  while (my ($k, $v) = splice(@_, 0, 2)) {
    push @saved, $k, $self->{$k};
    $self->{$k} = $v;
  }

  return guard { hash_merge($self, @saved) };
}


###############
# Generate URIs

has 'uri_helper' => (
  isa => 'CodeRef',
  is  => 'ro',
);

method uri () {
  return unless exists $self->{uri_helper};
  return $self->{uri_helper}->($self, @_);
}


############################
# Context stash manipulation

has 'stash' => (
  isa     => 'HashRef',
  is      => 'bare',
  default => sub { {} },
);

method stash () {
  my $s = $self->{stash};
  hash_merge($s, @_) if @_;

  return $s;
}


###################
# Buffer management

has 'buffer' => (
  isa     => 'Str',
  is      => 'bare',
  default => '',
);

method clear_buffer () {
  my $b = $self->{buffer};

  $self->{buffer} = '';

  return $b;
}

method buffer () {
  if (@_) {
    local $" = '';
    $self->{buffer} .= "@_";
  }

  return $self->{buffer};
}

method buffer_wrap ($pre, $post?) {
  $self->{buffer} = $pre . $self->{buffer} if $pre;
  $self->{buffer} .= $post if $post;

  return $self->{buffer};
}



has 'buffer_stack' => (
  isa => 'ArrayRef',
  is  => 'bare',
  default => sub { [] },
);

method buffer_stack ($buffer?) {
  push @{$self->{buffer_stack}}, $self->clear_buffer;
  $self->buffer($buffer) if $buffer;

  return;
}

method buffer_merge ($buffer?) {
  $self->buffer($buffer) if defined $buffer;
  $self->buffer(pop @{$self->{buffer_stack}}, $self->clear_buffer);
}


#############
# Model links

has 'model' => (isa => 'Ferdinand::Model', is => 'rw');

has 'item' => (isa => 'Object', is => 'rw');
has 'set'  => (isa => 'Object', is => 'rw');

has 'id' => (isa => 'ArrayRef', is => 'bare');

method id () {
  return unless exists $self->{id};
  return @{$self->{id}};
}


##################
# Error management

has 'errors' => (
  traits  => ['Hash'],
  is      => 'bare',
  isa     => 'HashRef',
  default => sub { {} },
  handles => {
    add_error    => 'set',
    error_for    => 'get',
    has_errors   => 'count',
    errors       => 'kv',
    clear_errors => 'clear',
  },
);


#################
# Form management

has 'form' => (
  is         => 'ro',
  isa        => 'Ferdinand::Form',
  lazy_build => 1,
  handles    => [
    qw(
      render_field render_field_read render_field_write
      field_value_str field_value
      )
  ],
);

sub _build_form { return Ferdinand::Form->new(ctx => $_[0]) }

__PACKAGE__->meta->make_immutable;
1;
