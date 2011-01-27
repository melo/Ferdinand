package Ferdinand::Widgets::List;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template find_structure);
use Carp 'confess';

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::ColumnSet', 'Ferdinand::Roles::Title';

method render_self ($ctx) {
  $self->render_list($ctx, $self->_get_elems($ctx));
}

method render_list ($ctx, $elems) {
  $ctx->buffer(
    render_template(
      'list.pltj',
      { ctx   => $ctx,
        elems => $elems,
      }
    )
  );
}

method _get_elems ($ctx) {
  my $id = $self->id;
  my $p  = $ctx->params;

  my $elems;
  if (find_structure($p, "${id}.init")) {
    $elems = find_structure($p, "${id}.items");
  }
  elsif (my $rs = $ctx->set) {
    while (my $row = $rs->next) {
      push @$elems, $self->_get_columns_from_item($ctx, $row);
    }
  }

  return $elems || [];
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ list.pltj
<?pl #@ARGS ctx, elems ?>
<?pl my $model = $ctx->model; ?>
<?pl my $widget = $ctx->widget; ?>
<?pl my $col_names = $widget->col_names; ?>

[== $widget->render_title($ctx, {class => "w_list"}) =]

<table cellspacing="1" class="ordenada1 w_list">
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
<?pl if (@$elems) { ?>
<?pl   for my $row (@$elems) { ?>
    <tr>
<?pl     for my $col (@$col_names) { ?>
      <td>[== $row->{$col} =]</td>
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
