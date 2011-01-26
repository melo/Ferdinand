package Ferdinand::Roles::WidgetContainer;

use Ferdinand::Setup 'role';
use Ferdinand::Utils qw( load_widget );
use Method::Signatures;

requires 'render_self', 'setup_attrs', 'setup_check_self';

has 'layout' => (
  traits  => ['Array'],
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
  handles => {widgets => 'elements'},
);

has 'on_demand' => (
  isa     => 'Bool',
  is      => 'ro',
  default => 0,
);

after setup_fields => method ($fields) { push @$fields, 'on_demand' };


after setup_attrs => method ($class:, $attrs, $meta, $sys?, $stash = {}) {
  my $layout = delete $meta->{layout} || [];

  my @widgets;
  for my $widget_spec (@$layout) {
    my $widget_class = delete $widget_spec->{type};
    confess "Missing widget 'type', "
      unless $widget_class;

    $widget_class = load_widget($widget_class);
    push @widgets, $widget_class->setup($widget_spec, $sys, $stash);
  }

  $attrs->{layout} = \@widgets;
};


after setup_check_self => method ($ctx) {
  $_->setup_check($ctx) for $self->widgets;
};


after render_self => method($ctx) {
  return if $self->on_demand;

  $self->render_widgets($ctx);
};


method render_widgets ($ctx) {
  $_->render($ctx) for $self->widgets;
}


1;
