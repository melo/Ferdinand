package Ferdinand::Widgets::Form::Button;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Ferdinand::Utils 'render_template';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::WidgetContainer';

has 'label'  => (isa => 'Str', is => 'ro', required   => 1);
has 'btn_id' => (isa => 'Str', is => 'ro', lazy_build => 1);

method _build_btn_id () {
  my $l = lc($self->label);
  $l =~ s/ /_/g;

  return join('_', 'btn', $self->id, $l);
}

method setup_attrs($class:, $attrs, $meta) {
  ## Remove known attributes
  for my $f (qw( label )) {
    $attrs->{$f} = delete $meta->{$f}
      if exists $meta->{$f};
  }
}

method render_self($ctx) {
  $ctx->buffer(render_template('button.pltj', {ctx => $ctx}));

  return unless $ctx->mode eq 'create_ok';
  return unless $ctx->params->{$self->btn_id};

  $self->render_widgets;
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ button.pltj
<?pl #@ARGS ctx ?>
<?pl my $w = $ctx->widget; ?>
<?pl my $label = $w->label; ?>
<?pl my $name  = $w->btn_id; ?>

<input type="submit" name="[= $name =]" id="[= $name =]" value="[= $label =]">
