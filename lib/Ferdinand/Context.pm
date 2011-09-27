package Ferdinand::Context;

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw( hash_merge );
use Guard 'guard';
use Method::Signatures;
use namespace::clean -except => 'meta';

with 'Ferdinand::Roles::ErrorRegistry';


#################
# Main attributes

has 'widget' => (isa => 'Ferdinand::Widget', is => 'rw');

has 'params' => (isa => 'HashRef', is => 'ro', default => sub { {} });

has 'mode' => (isa => 'Str', is => 'ro', default => 'view');

## TODO: use self_uri or some other less-Catalyst name
has 'action_uri' => (isa => 'URI', is => 'ro');


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

method clone (@_) {
  return ref($self)->new(%$self, @_, buffer => '', parent => $self);
}

method DEMOLISH (@_) {
  my $p = $self->parent;
  return unless $p;

  my $b = $self->buffer;
  return unless length($b);

  $p->buffer($b);
}

method overlay (@_) {
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

method snapshot (@_) {
  my @saved;

  my @fields = qw( model set item id prefix );
  push @saved, $_, $self->{$_} for @fields;

  while (my ($k, $v) = splice(@_, 0, 2)) {
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

method stash (@_) {
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

method buffer (@_) {
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

has 'model' => (
  isa       => 'Ferdinand::Model',
  is        => 'rw',
  clearer   => 'clear_model',
  predicate => 'has_model',
);
has 'item' => (
  isa       => 'Object',
  is        => 'rw',
  clearer   => 'clear_item',
  predicate => 'has_item',
);
has 'set' => (
  isa       => 'Object',
  is        => 'rw',
  clearer   => 'clear_set',
  predicate => 'has_set',
);
has 'id' => (
  isa       => 'ArrayRef',
  is        => 'bare',
  clearer   => 'clear_id',
  predicate => 'has_id',
);

has 'prefix' => (isa => 'Str', is => 'rw', default => '');

method id () {
  return unless exists $self->{id};
  return @{$self->{id}};
}

method render_field (@_) {
  $self->model->render_field(ctx => $self, @_);
}

method render_field_read (@_) {
  $self->model->render_field_read(ctx => $self, @_);
}

method render_field_write (@_) {
  $self->model->render_field_write(ctx => $self, @_);
}

method field_value (@_) {
  $self->model->field_value(ctx => $self, @_);
}

method field_value_str (@_) {
  $self->model->field_value_str(ctx => $self, @_);
}

method id_for_item ($item) {
  return $self->model->id_for_item($item || $self->item);
}


__PACKAGE__->meta->make_immutable;
1;
