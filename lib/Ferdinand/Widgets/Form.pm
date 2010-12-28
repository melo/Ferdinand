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
<?pl
  if (my $item = $ctx->item) {
    my @pk_cols = $ctx->model->primary_columns;
    for my $col (@pk_cols) {
      my $val = $ctx->field_value_str($col);
?>
  <input type="hidden" name="[= $col =]" value="[= $val =]">
<?pl
    }
  }
?>
  <input type="hidden" name="submited" value="1">
  [== $content =]
</form>
