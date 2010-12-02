package Ferdinand::Roles::WidgetContainer;

use Ferdinand::Setup 'role';
use Method::Signatures;

requires 'render_self', 'setup_attrs';

has 'layout' => (
  traits  => ['Array'],
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
  handles => {widgets => 'elements'},
);

has 'clone' => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has 'mode_filter' => (
  isa     => 'Str',
  is      => 'ro',
  default => '',
);


after setup_attrs => sub {
  my ($class, $attrs, $meta, $sys, $stash) = @_;

  my $layout = delete $meta->{layout};
  confess "Requires 'layout' section but none found, "
    unless $layout && @$layout;

  my @widgets;
  for my $widget_spec (@$layout) {
    my $widget_class = delete $widget_spec->{type};
    confess "Missing widget 'type', "
      unless $widget_class;

    $widget_class = "Ferdinand::Widgets::$widget_class"
      unless $widget_class =~ s/^\+//;
    eval "require $widget_class";
    confess("Could not load widget '$widget_class': $@, ") if $@;

    push @widgets, $widget_class->setup($widget_spec, $sys, $stash);
  }

  $attrs->{layout} = \@widgets;

  for my $attr (qw( clone mode_filter )) {
    $attrs->{$attr} = delete $meta->{$attr} if exists $meta->{$attr};
  }
};


after render_self => sub {
  my ($self, $ctx) = @_;
  my $m = $self->mode_filter;
  return if $m && $ctx->mode ne $m;

  my $c = $ctx;
  $c = $ctx->clone if $self->clone;

  $_->render($c) for $self->widgets;
};


1;
