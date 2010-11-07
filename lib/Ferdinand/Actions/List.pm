package Ferdinand::Actions::List;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils 'render_template';

extends 'Ferdinand::Action';


method render ($ctx) {
  my $rows = $self->impl->fetch_rows($self, $ctx);

  return (
    output => render_template(
      'list.pltj',
      { action    => $self,
        col_names => $self->column_names,
        cols      => $self->columns,
        rows      => $rows,
        ctx       => $ctx,
      }
    )
  );
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ list.pltj
<?pl #@ARGS action, cols, col_names, rows, ctx ?>

<table cellspacing="1" class="ordenada1">
  <thead>
    <tr>
<?pl
  for my $col (@$col_names) {
    my $ci = $cols->{$col};
?>
      <th[== $ci->{cls_list_html} =]>[= $ci->{label} =]</th>
<?pl } ?>
    </tr>
  </thead>
  <tbody>
<?pl  if (@$rows) { ?>
<?pl    for my $row (@$rows) { ?>
    <tr>
<?pl      for my $col (@$col_names) {
            my $html = $action->render_field(
             col      => $col,
             row      => $row,
             col_info => $cols->{$col},
             ctx      => $ctx
            );
?>
      <td>[== $html =]</td>
<?pl      } ?>
    </tr>
<?pl    } ?>
<?pl  } ?>
<?pl  else { my $n_cols = @$cols; ?>
    <tr colspan="[= $n_cols =]">Não existem registos para listar</tr>
<?pl  } ?>
  </tbody>
</table>
