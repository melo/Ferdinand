package Ferdinand::Map;

# ABSTRACT: Base class for Ferdinand implementations

use Ferdinand::Setup 'class';
use Ferdinand::Context;
use Method::Signatures;

with 'Ferdinand::Roles::Setup';

############
# Action map

has 'actions' => (
  traits      => ['Hash'],
  isa         => 'HashRef[Ferdinand::Action]',
  is          => 'bare',
  default     => sub { {} },
  handles     => {
    actions        => 'values',
    action_for     => 'get',
    has_action_for => 'exists',
  },
);


after setup_attrs => method ($class:, $attrs, $meta, $sys, $stash) {
  my $action_list = delete($meta->{actions}) || [];
  confess "Requires a 'actions' specification, "
    unless @$action_list;

  my $a_class = $sys->action_class_name;
  eval "require $a_class";
  confess($@) if $@;

  my %map;
  for my $action_meta (@$action_list) {
    delete $stash->{widget_ids};
    my $action = $a_class->setup($action_meta, $sys, $stash);
    $map{$action->name} = $action;
  }

  $attrs->{actions} = \%map;
};


after setup_check_self => method ($ctx) {
  $_->setup_check($ctx) for $self->actions;
};


method render ($action, $args = {}) {
  if (!blessed($action)) {
    confess "No action named '$action', "
      unless $self->has_action_for($action);

    $action = $self->action_for($action);
  }

  return $self->sys->render($action, $args);
}


__PACKAGE__->meta->make_immutable;
1;
