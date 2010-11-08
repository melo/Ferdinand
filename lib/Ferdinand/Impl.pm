package Ferdinand::Impl;

# ABSTRACT: Base class for Ferdinand implementations

use Ferdinand::Setup 'class';
use Ferdinand::Actions::List;
use Ferdinand::Actions::View;
use Method::Signatures;

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
  for my $action_name (qw( list view )){
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

  $ctx->{impl} = $self;
  my $action = $ctx->{action} = $self->action_for($action_name);
  my %output = $action->render($ctx);

  return {
    title       => $action->page_title($ctx),
    action      => $action,
    action_name => $action_name,
    %output,
    ctx => $ctx,
  };
}


method render_field (:$col, :$ctx, :$row, :$col_info) {
  my $v = $row->{$col};
  $v = $col_info->{formatter}->($v) if $col_info->{formatter};

  my $url;
  if ($url = $col_info->{linked}) {
    $url = $ctx->{uri_helper}->($url, $row->{_id});
  }
  elsif ($url = $col_info->{link_to}) {
    $url = $url->($row, $ctx);
  }

  if ($url) {
    $v = ghtml()->a({href => $url}, $v);
  }
  else {
    $v = ehtml($v);
  }

  return $v;
}


method column_meta_fixup ($name, $info) {}


__PACKAGE__->meta->make_immutable;
1;
