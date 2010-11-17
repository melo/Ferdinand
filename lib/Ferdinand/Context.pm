package Ferdinand::Context;

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw( ehtml ghtml );
use Method::Signatures;

#################
# Main attributes

has 'ferdinand' => (isa => 'Ferdinand',         is => 'ro', required => 1);
has 'action'    => (isa => 'Ferdinand::Action', is => 'ro', required => 1);
has 'widget'    => (isa => 'Ferdinand::Widget', is => 'rw');

has 'params' => (isa => 'HashRef', is => 'ro', default => sub { {} });


#################
# Clone a context

has 'parent' => (isa => 'Ferdinand::Context', is => 'ro');

method clone () {
  return ref($self)->new(%$self, @_, buffer => '', parent => $self);
}

method DEMOLISH () {
  my $b = $self->buffer;
  $self->parent->buffer($b) if $b;
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
  _merge($s, @_) if @_;

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
  $self->{buffer} = '';
}

method buffer () {
  if (@_) {
    local $" = '';
    $self->{buffer} .= "@_";
  }

  return $self->{buffer};
}


#############
# Model links Moose

has 'item' => (isa => 'HashRef',  is => 'rw');
has 'set'  => (isa => 'ArrayRef', is => 'rw');

has 'id' => (isa => 'ArrayRef', is => 'bare');

method id () {
  return unless exists $self->{id};
  return @{$self->{id}};
}


##################
# Render of fields

# TODO: is this the proper place for this code? No better place for it *yet*...
method render_field (:$field, :$item, :$meta) {
  my $v = $item->{$field};

  if (my $f = $meta->{formatter}) {
    local $_ = $v;
    $v = $f->($self);
  }

  my $url;
  if ($url = $meta->{linked}) {
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
