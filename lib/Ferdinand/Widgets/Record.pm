package Ferdinand::Widgets::Record;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template);
use Carp 'confess';

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::ColumnSet', 'Ferdinand::Roles::Title';

has 'not_found_msg' => (
  isa     => 'Str',
  is      => 'ro',
  default => 'Não existem registos para listar',
);

after setup_fields => method($fields) {push @$fields, qw(not_found_msg)};


method render_self_read ($ctx) {
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
<?pl my $model = $ctx->model; ?>
<?pl my $widget = $ctx->widget; ?>
<?pl my $col_names = $widget->col_names; ?>

[== $widget->render_title($ctx) =]

<table cellspacing="1">
<?pl if ($ctx->item) { ?>
	<colgroup>
		<col width="20%"></col>
		<col width="80%"></col>
	</colgroup>
  <tbody>
<?pl  for my $col (@$col_names) {
        my $meta = $model->field_meta($col);
        my $html = $ctx->render_field(field => $col);
?>
    <tr>
      <th>[= $meta->{label} =]:</th>
      <td>[== $html =]</td>
    </tr>
<?pl  } ?>
  </tbody>
<?pl } else { ?>
	<colgroup>
		<col width="100%"></col>
	</colgroup>
  <tbody>
    <tr><td>[= $widget->not_found_msg =]</td></tr>
  </tbody>
<?pl } ?>
</table>

@@ form.pltj
<?pl #@ARGS ctx ?>
<?pl my $model = $ctx->model; ?>
<?pl my $widget = $ctx->widget; ?>
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
<?pl   for my $col (@$col_names) {
         my $meta = $model->field_meta($col);
         my $err  = $ctx->error_for($col);
         my $html = $ctx->render_field(
           field => $col,
           item  => ($params->{submited}? $params : $ctx->item),
         );
?>
    <tr>
      <th[== $err? ' class="errof"' : '' =]>[= $meta->{label} =]:</th>
<?pl     if ($err) { ?>
      <td>[== $html =] <span class="errom">[= $err =]</span></td>
<?pl     } else { ?>
      <td>[== $html =]</td>
<?pl     } ?>
    </tr>
<?pl   } ?>
  </tbody>
</table>
