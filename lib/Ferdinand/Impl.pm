package Ferdinand::Impl;

# ABSTRACT: Base class for Ferdinand implementations

use Ferdinand::Moose;
use Ferdinand::Actions::List;
use Method::Signatures;
use namespace::clean -except => 'meta';

has '_actions' => (
  traits      => ['Hash'],
  isa         => 'HashRef[Ferdinand::Action]',
  is          => 'ro',
  default     => sub { {} },
  initializer => undef,
  handles     => {
    add_action     => 'set',
    action_for     => 'get',
    actions        => 'values',
    has_action_for => 'exists',
  },
);


method setup_actions($meta) {
  ## TODO: move this to a Module::Plugable system
  for my $action_name (qw( list )){
    my $info = delete $meta->{$action_name};
    next unless $info;
    
    my $action_class = "Ferdinand::Actions::".ucfirst($action_name);
    my $action = $action_class->setup($self, $info);
    
    $self->add_action($action_name => $action);
  }
}


method render ($action_name, $ctx = {}) {
  confess "No action named '$action_name', "
    unless $self->has_action_for($action_name);

  my $action = $self->action_for($action_name);
  my $output = $action->render($self, $ctx);

  return {
    output      => $output,
    action      => $action,
    action_name => $action_name,
    ctx         => $ctx,
  };
}


method column_meta_fixup ($name, $info) {}


__PACKAGE__->meta->make_immutable;
1;
