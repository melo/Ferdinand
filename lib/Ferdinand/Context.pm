package Ferdinand::Context;

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw( ehtml ghtml hash_merge );
use Guard 'guard';
use Method::Signatures;

#################
# Main attributes

has 'map' => (isa => 'Ferdinand::Map', is => 'ro', required => 1);
has 'widget' => (isa => 'Ferdinand::Widget', is => 'rw');

has 'params' => (isa => 'HashRef', is => 'ro', default => sub { {} });

has 'mode' => (isa => 'Str', is => 'ro', default => 'view');

has 'action' => (isa => 'Ferdinand::Action', is => 'ro', required => 1);
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
  return unless $b;

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
# Model links Moose

has 'model' => (isa => 'Ferdinand::Model', is => 'rw');

has 'item' => (isa => 'Object', is => 'rw');
has 'set'  => (isa => 'Object', is => 'rw');

has 'id' => (isa => 'ArrayRef', is => 'bare');

method id () {
  return unless exists $self->{id};
  return @{$self->{id}};
}


##################
# Render of fields

# TODO: is this the proper place for this code? No better place for it *yet*...
method render_field (:$field, :$meta = {}, :$item) {
  my $m = $self->mode;
  return $self->render_field_read(@_) if $m eq 'view';
  return $self->render_field_write(@_) if $m eq 'create' || $m eq 'create_ok';
}

method render_field_read (:$field, :$meta = {}, :$item) {
  $item = $self->item unless $item;
  my $v = $item->$field();
  return '' unless defined $v;

  if (my $f = $meta->{formatter}) {
    local $_ = $v;
    $v = $f->($self);
  }

  my $url;
  if ($url = $meta->{linked}) {
    local $_ = $item;
    $url = $self->uri($url);
  }
  elsif ($url = $meta->{link_to}) {
    local $_ = $item;
    $url = $url->($self);
  }

  if ($url) {
    $v = ghtml()->a({href => $url}, $v);
  }
  else {
    $v = ehtml($v);
  }

  return $v;
}

method render_field_write (:$field, :$meta = {}, :$item = {}) {
  my $type  = $meta->{data_type} || '';
  my %attrs = (
    id    => $field,
    name  => $field,
    type  => 'text',
    value => $item->{$field},
  );

  $attrs{required} = 1 unless $meta->{is_nullable};

  if (my $opt = $meta->{options}) {
    my @inner = map { ghtml()->option({value => $_}, $_) } @$opt;
    return ghtml()->select({name => $field}, @inner);
  }
  elsif ($type eq 'char' || $type eq 'varchar') {
    if (my $size = $meta->{size}) {
      $attrs{maxlength} = $size;
      $attrs{size}      = $size;
    }
  }
  elsif ($type eq 'date') {
    $attrs{type} = 'date';
  }

  return ghtml()->input(\%attrs);
}

method field_value ($field, $type, $item?) {
  $item = $self->item unless $item;
  return unless $item;

  return $item->$field() if blessed($item) and $item->can($field);
  return $item->{$field} if ref($item) eq 'HASH';
  return;
}

method field_value_str ($field, $type, $item?) {
  my $v = $self->field_value(@_);
  return '' unless $v;
  return $v unless ref($v);

  if (blessed($v) eq 'DateTime') {
    return $v->ymd('/') if $type eq 'date';
    return $v->ymd('/') . ' ' . $v->hms;
  }

  return "$v";
}


__PACKAGE__->meta->make_immutable;
1;
