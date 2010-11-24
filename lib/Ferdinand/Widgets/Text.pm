package Ferdinand::Widgets::Text;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw( render_template );
use Text::Markdown ();

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::ColumnSet';

method render_self ($ctx) {
  confess('Record widget requires a valid item() in Context,') unless $ctx->item;
  $ctx = $ctx->clone(widget => $self);
  $ctx->buffer(render_template('text.pltj', {ctx => $ctx, mkdn => Text::Markdown->new}));
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ text.pltj
<?pl #@ARGS ctx, mkdn ?>
<?pl my $widget = $ctx->widget; ?>
<?pl my $meta = $widget->col_meta; ?>
<?pl my $cols = $widget->col_names; ?>
<?pl my $item = $ctx->item; ?>

<?pl  for my $col (@$cols) {
        my $ci = $meta->{$col};
        my $v = $item->$col() || '-- sem texto definido --';
?>
<h1>[= $ci->{label} =]</h1>
<div>
  [== $mkdn->markdown($v) =]
</div>
<?pl } ?>