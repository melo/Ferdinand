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
    action_for     => 'get',
    has_action_for => 'exists',
  },
);

method setup_attrs ($class:, $attrs, $meta, $sys, $stash) {
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


method render ($action_name, $args = {}) {
  confess "No action named '$action_name', "
    unless $self->has_action_for($action_name);

  my $action = $self->action_for($action_name);

  my %ctx_args = (
    map    => $self,
    action => $action,
  );
  $ctx_args{id}         = $args->{id}         if exists $args->{id};
  $ctx_args{mode}       = $args->{mode}       if exists $args->{mode};
  $ctx_args{params}     = $args->{params}     if exists $args->{params};
  $ctx_args{uri_helper} = $args->{uri_helper} if exists $args->{uri_helper};
  $ctx_args{action_uri} = $args->{action_uri} if exists $args->{action_uri};

  my $ctx = Ferdinand::Context->new(%ctx_args);
  $action->render($ctx);

  my $mode = $ctx->mode;
  if ($ctx->has_errors && $mode =~ /^(.+)_do$/) {
    $mode = $1;
    my $g = $ctx->overlay(mode => $mode);
    $ctx->clear_buffer;
    $action->render($ctx);
  }

  return $ctx;
}

__PACKAGE__->meta->make_immutable;
1;
