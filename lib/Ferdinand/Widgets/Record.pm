package Ferdinand::Widgets::Record;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template);
use Carp 'confess';

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::ColumnSet', 'Ferdinand::Roles::Title';

method render_self ($ctx) {
  my $m = $ctx->mode;

  my $t;
  if ($m eq 'view') {
    confess('Record widget requires a valid item() in Context,')
      unless $ctx->item;
    $t = 'view.pltj';
  }
  elsif ($m eq 'create' || $m eq 'create_do') {
    $t = 'create.pltj';
  }
  else {
    confess("Context mode '$m' is not supported by Record widget");
  }

  $ctx->buffer(render_template($t, {ctx => $ctx}));
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ view.pltj
<?pl #@ARGS ctx ?>
<?pl my $widget = $ctx->widget; ?>
<?pl my $cols = $widget->col_meta; ?>
<?pl my $col_names = $widget->col_names; ?>

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


@@ create.pltj
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
        my $ci = $cols->{$col};
        my $html = $ctx->render_field(
          field => $col,
          meta  => $ci,
          item  => $params,
        );
?>
        <tr>
            <th>[= $ci->{label} =]:</th>
            <td>[== $html =]</td>
        </tr>
<?pl  } ?>
    </tbody>
</table>
