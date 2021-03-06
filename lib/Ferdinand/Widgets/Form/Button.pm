package Ferdinand::Widgets::Form::Button;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Ferdinand::Utils 'render_template';
use Text::Unaccent 'unac_string';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::WidgetContainer';

has 'label' => (isa => 'Str', is => 'ro', required => 1);
has 'btn_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => method () {
    my $l = lc($self->label);
    $l =~ s/ /_/g;
    $l = unac_string('utf8', $l);

    return join('_', 'btn', $self->id, $l);
  }
);

after setup_fields => method($fields) {push @$fields, 'label', 'btn_id'};


method render_self ($ctx) {
  $ctx->buffer(render_template('button.pltj', {ctx => $ctx}));

  return unless $ctx->mode =~ /_do$/;
  return unless $ctx->params->{$self->btn_id};

  $self->render_widgets($ctx);
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
