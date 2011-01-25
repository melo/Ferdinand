package Ferdinand::Widgets::List;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template);
use Carp 'confess';

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::ColumnSet', 'Ferdinand::Roles::Title';

method render_self ($ctx) {
  confess('List widget requires a valid set() in Context,')
    unless $ctx->set;
  $ctx->buffer(render_template('list.pltj', {ctx => $ctx}));
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ list.pltj
<?pl #@ARGS ctx ?>
<?pl my $model = $ctx->model; ?>
<?pl my $widget = $ctx->widget; ?>
<?pl my $col_names = $widget->col_names; ?>
<?pl my @rows = $ctx->set->all; ?>

[== $widget->render_title($ctx) =]

<table cellspacing="1" class="ordenada1">
  <thead>
    <tr>
<?pl
     for my $col (@$col_names) {
       my $meta = $model->field_meta($col);
?>
      <th[== $meta->{cls_list_html} =]>[= $meta->{label} =]</th>
<?pl } ?>
    </tr>
  </thead>
  <tbody>
<?pl if (@rows) { ?>
<?pl   for my $row (@rows) { ?>
    <tr>
<?pl     for my $col (@$col_names) {
           my $html = $ctx->render_field_read(
              field => $col,
              item  => $row,
           );
?>
      <td>[== $html =]</td>
<?pl     } ?>
    </tr>
<?pl   } ?>
<?pl } ?>
<?pl else {
       my $n_cols = @$col_names; ?>
    <tr><td colspan="[= $n_cols =]">Não existem registos para listar</td></tr>
<?pl } ?>
  </tbody>
</table>
