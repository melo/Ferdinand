package Ferdinand::Context;

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw( hash_merge );
use Guard 'guard';
use Method::Signatures;

#################
# Main attributes

has 'map' => (isa => 'Ferdinand::Map', is => 'ro');
has 'action' => (isa => 'Ferdinand::Action', is => 'ro');

has 'widget' => (isa => 'Ferdinand::Widget', is => 'rw');

has 'params' => (isa => 'HashRef', is => 'ro', default => sub { {} });

has 'mode' => (isa => 'Str', is => 'ro', default => 'view');

## TODO: use self_uri or some other less-Catalyst name
has 'action_uri' => (isa => 'URI', is => 'ro');

## TODO: this is too App specific, maybe move back to per-app Context class?
has 'uri_helper' => (
  isa => 'Object',
  is  => 'ro',
);


#################
# Mode management

method is_mode_read () {
  return 1 if $self->mode =~ /^(?:list|view)?$/;
  return;
}

method is_mode_write () {
  return 1 if $self->mode =~ /^(?:edit|create)(?:_do)?$/;
  return;
}


######################
# HTML Buttons helpers

method was_button_used ($btn, $prefix?) {
  my $p = $self->params;

  if ($prefix) {
    my $re = qr{^${btn}_(.+)$};
    for my $i (keys %$p) {
      next unless $i =~ m/$re/;
      return $1;
    }
  }
  else {
    return 1 if exists $p->{$btn};
  }

  return;
}


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
    if (defined $v) {
      $self->{$k} = $v;
    }
    else {
      delete $self->{$k};
    }
  }

  return guard { hash_merge($self, @saved) };
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
has 'item'  => (isa => 'Object',           is => 'rw');
has 'set'   => (isa => 'Object',           is => 'rw');
has 'id'    => (isa => 'ArrayRef',         is => 'bare');

has 'prefix' => (isa => 'Str', is => 'rw', default => '');

method id () {
  return unless exists $self->{id};
  return @{$self->{id}};
}

method render_field () {
  $self->model->render_field(ctx => $self, @_);
}

method render_field_read () {
  $self->model->render_field_read(ctx => $self, @_);
}

method render_field_write () {
  $self->model->render_field_write(ctx => $self, @_);
}

method field_value () {
  $self->model->field_value(ctx => $self, @_);
}

method field_value_str () {
  $self->model->field_value_str(ctx => $self, @_);
}

method id_for_item ($item) {
  return $self->model->id_for_item($item || $self->item);
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


__PACKAGE__->meta->make_immutable;
1;
