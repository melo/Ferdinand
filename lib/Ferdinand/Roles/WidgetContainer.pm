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

has 'on_demand' => (
  isa     => 'Bool',
  is      => 'ro',
  default => 0,
);


after setup_attrs => sub {
  my ($class, $attrs, $meta, $sys, $stash) = @_;
  my $layout = delete $meta->{layout} || [];

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

  for my $attr (qw( clone on_demand )) {
    $attrs->{$attr} = delete $meta->{$attr} if exists $meta->{$attr};
  }
};


after render_self => sub {
  my ($self, $ctx) = @_;
  return if $self->on_demand;

  $self->render_widgets($ctx);
};

method render_widgets ($ctx) {
  $ctx = $ctx->clone if $self->clone;

  $_->render($ctx) for $self->widgets;
}


1;
