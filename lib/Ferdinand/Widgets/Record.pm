package Ferdinand::Widgets::Record;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template);
use Carp 'confess';

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::ColumnSet', 'Ferdinand::Roles::Title';

method render_self_read ($ctx) {
  ## FIXME: better to skip with warning?
  confess('Record widget requires a valid item() in Context,')
    unless $ctx->item;

  $ctx->buffer(render_template('view.pltj', {ctx => $ctx}));
}

method render_self_write ($ctx) {
  $ctx->buffer(render_template('form.pltj', {ctx => $ctx}));
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ view.pltj
<?pl #@ARGS ctx ?>
<?pl my $widget = $ctx->widget; ?>
<?pl my $cols = $widget->col_meta; ?>
<?pl my $col_names = $widget->col_names; ?>

[== $widget->render_title($ctx) =]

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


@@ form.pltj
<?pl #@ARGS ctx ?>
<?pl my $widget = $ctx->widget; ?>
<?pl my $cols = $widget->col_meta; ?>
<?pl my $col_names = $widget->col_names; ?>
<?pl my $params = $ctx->params; ?>

<?pl if (my $title = $widget->title($ctx)) { ?>
<h1>[= $title =]</h1>
<?pl } ?>

<table cellspacing="1">
	<colgroup>
		<col width="20%"></col>
		<col width="80%"></col>
	</colgroup>
    <tbody>
<?pl  for my $col (@$col_names) {
        my $ci   = $cols->{$col};
        my $err  = $ctx->error_for($col);
        my $html = $ctx->render_field(
          field => $col,
          meta  => $ci,
          item  => ($params->{submited}? $params : $ctx->item),
        );
?>
        <tr>
            <th[== $err? ' class="errof"' : '' =]>[= $ci->{label} =]:</th>
<?pl if ($err) { ?>
            <td>[== $html =] <span class="errom">[= $err =]</span></td>
<?pl } ?>
<?pl else { ?>
            <td>[== $html =]</td>
<?pl } ?>
        </tr>
<?pl  } ?>
    </tbody>
</table>
