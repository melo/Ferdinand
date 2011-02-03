package Ferdinand::Widgets::Form::Buttons;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Ferdinand::Utils 'render_template';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::WidgetContainer';

has 'class' => (isa => 'Str', is => 'ro', required => 1, default => 'w_form_buttons');

after setup_fields => method($fields) {push @$fields, 'class'};


method render_begin ($ctx) {
  $ctx->buffer_stack;
}

method render_end ($ctx) {
  $ctx->buffer(
    render_template(
      'buttons.pltj', {ctx => $ctx, content => $ctx->clear_buffer}
    )
  );
  $ctx->buffer_merge;
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ buttons.pltj
<?pl #@ARGS ctx, content ?>

<div class="[= $ctx->widget->class =]">
[== $content =]
</div>
