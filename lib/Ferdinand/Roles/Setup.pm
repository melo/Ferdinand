package Ferdinand::Roles::Setup;

use Ferdinand::Setup 'role';
use Method::Signatures;

has 'sys' => (
  isa => 'Str',
  is  => 'ro',
);

has 'id' => (
  isa => 'Str',
  is  => 'ro',
  required => 1
);

method setup ($class:, $meta, $sys, $stash) {
  my %attrs;

  $class->setup_init($meta, $sys, $stash);

  my @fields;
  $class->setup_fields(\@fields);
  for my $f (@fields) {
    $attrs{$f} = delete $meta->{$f} if exists $meta->{$f};
  }

  $class->setup_attrs(\%attrs, $meta, $sys, $stash);

  $attrs{id} = 'w_' . ++$stash->{widget_ids} unless exists $attrs{id};
  $attrs{sys} = $sys;

  my $self = $class->new(%attrs);
  $self->setup_done($stash);

  return $self;
}

method setup_init ($class:, $meta, $sys, $stash) {}
method setup_attrs ($class:, $attrs, $meta, $sys, $stash) {}
method setup_done ($stash) {}
method setup_fields ($fields) {}


#########################################
# Check the tree setup: a visitor pattern

method setup_check ($ctx) {
  my @guards = ($ctx->overlay(widget => $self));

  $self->setup_check_begin($ctx, \@guards);
  $self->setup_check_self($ctx);

  return;
}

method setup_check_begin ($ctx, $guards) {}
method setup_check_self ($ctx) {}

1;
