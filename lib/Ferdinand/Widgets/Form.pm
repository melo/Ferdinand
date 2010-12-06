package Ferdinand::Widgets::Form;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Ferdinand::Utils 'render_template';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::WidgetContainer';

method render_begin ($ctx) {
  $ctx->buffer_stack;
}


method render_end ($ctx) {
  $ctx->buffer(
    render_template(
      'form.pltj', {ctx => $ctx, content => $ctx->clear_buffer}
    )
  );
  $ctx->buffer_merge;
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ form.pltj
<?pl #@ARGS ctx, content ?>

<form action="[= $ctx->action_uri->path =]" method="POST" accept-charset="utf-8">
  [== $content =]
</form>