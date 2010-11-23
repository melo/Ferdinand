package Ferdinand::Widgets::Record;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template);
use Carp 'confess';

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::ColumnSet';

method render_self ($ctx) {
  confess('Record widget requires a valid item() in Context,') unless $ctx->item;
  $ctx = $ctx->clone(widget => $self);
  $ctx->buffer(render_template('view.pltj', {ctx => $ctx}));
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ view.pltj
<?pl #@ARGS ctx ?>
<?pl my $widget = $ctx->widget; ?>
<?pl my $cols = $widget->col_meta; ?>
<?pl my $col_names = $widget->col_names; ?>

<table cellspacing="1">
	<colgroup>
		<col width="20%"></col>
		<col width="80%"></col>
	</colgroup>
    <tbody>
<?pl  for my $col (@$col_names) {
        my $ci = $cols->{$col};
        my $html = $ctx->render_field(
          field => $col,
          meta  => $ci,
        );
?>
        <tr>
            <th>[= $ci->{label} =]:</th>
            <td>[== $html =]</td>
        </tr>
<?pl  } ?>
    </tbody>
</table>
