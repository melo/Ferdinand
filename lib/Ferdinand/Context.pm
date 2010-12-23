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


##################
# Render of fields

# TODO: is this the proper place for this code? No better place for it *yet*...
method render_field (:$field, :$meta = {}, :$item) {
  my $m = $self->mode;
  return $self->render_field_read(@_) if $m eq 'view' || $m eq 'list';
  return $self->render_field_write(@_) if $m eq 'create' || $m eq 'create_do';
  return $self->render_field_write(@_) if $m eq 'edit' || $m eq 'edit_do';
}

method render_field_read (:$field, :$meta = {}, :$item) {
  my $h = ghtml();

  $item = $self->item unless $item;
  my $v = $self->field_value_str($field, $meta, $item);

  my $type = $meta->{data_type} || '';

  my %attrs;
  my $cls = $meta->{cls_field_html};
  $attrs{class} = $cls if $cls;

  if (!defined $v) {
    return $h->div(\%attrs, '') if %attrs && $type eq 'text';
    return $h->span(\%attrs, '') if %attrs;
    return '';
  }

  my $url;
  if ($url = $meta->{linked}) {
    local $_ = $item;
    $url = $self->uri($url, [$item->id]);
  }
  elsif ($url = $meta->{link_to}) {
    local $_ = $item;
    $url = $url->($self);
  }

  my $opts = $meta->{options};
  if ($opts) {
    for my $o (@$opts) {
      next unless $v eq $o->{id};
      $v = $o->{name};
      last;
    }
  }

  my $fmt = $meta->{format} || '';
  if ($fmt eq 'html') {
    my $x = $v;
    $v = \$x;
  }

  if ($url) {
    $attrs{href} = $url;
    $v = $h->a(\%attrs, $v);
  }
  elsif (ref($v)) {
    $attrs{class} = $attrs{class} ? "$attrs{class} html_fmt" : 'html_fmt';
    $v = $h->div(\%attrs, $v);
  }
  elsif ($type eq 'text') {
    $v = $h->div(\%attrs, $v);
  }
  elsif (%attrs) {
    $v = $h->span(\%attrs, $v);
  }
  else {
    $v = ehtml($v);
  }

  return $v;
}

method render_field_write (:$field, :$meta = {}, :$item) {
  my $h    = ghtml();
  my $type = $meta->{data_type} || '';
  my $cls  = $meta->{cls_field_html};
  my $def  = $self->mode eq 'create' ? 1 : 0;
  my $val  = $self->field_value_str($field, $meta, $item, $def);

  my %attrs = (
    id   => $field,
    name => $field,
  );
  $attrs{class} = $cls if $cls;

  if ($meta->{format} && $meta->{format} eq 'html') {
    my $t = $val;
    $val = \$t;
  }

  if (my $opt = $meta->{options}) {
    my @inner;
    for my $opt (@$opt) {
      my $id = $opt->{id};
      my %oattrs = (value => $id);
      $oattrs{selected} = 1 if $val && $val eq $id;
      push @inner, $h->option(\%oattrs, $opt->{name});
    }
    return $h->select(\%attrs, @inner);
  }
  elsif ($type eq 'text') {
    $attrs{cols} = 100;
    $attrs{rows} = 6;
    if ($meta->{format} && $meta->{format} eq 'html') {
      $attrs{class} = $attrs{class} ? "$attrs{class} html_fmt" : 'html_fmt';
      $attrs{rows} += 12;
    }

    return $h->textarea(\%attrs, $val);
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

  $attrs{required} = 1      unless $meta->{is_nullable};
  $attrs{type}     = 'text' unless $attrs{type};
  $attrs{value}    = $val;

  return $h->input(\%attrs);
}

method field_value ($field, $item?) {
  $item = $self->item unless $item;
  return unless $item;

  return $item->$field() if blessed($item) and $item->can($field);
  return $item->{$field} if ref($item) eq 'HASH';
  return;
}

method field_value_str ($field, $meta = {}, $item?, $use_default = 0) {
  my $t = $meta->{data_type} || '';
  my $v = $self->field_value($field, $item);
  if (!$v && $use_default) {
    $v = $meta->{default_value};
    $v = $v->() if ref($v) eq 'CODE';
  }

  my $f = $meta->{formatter};
  if ($f && defined $v) {
    local $_ = $v;
    $v = $f->($self);
  }

  return '' unless defined $v;
  return $v unless ref($v);

  if (blessed($v) eq 'DateTime') {
    return $v->ymd('/') if $t eq 'date';
    return $v->ymd('/') . ' ' . $v->hms;
  }

  return "$v";
}


__PACKAGE__->meta->make_immutable;
1;
