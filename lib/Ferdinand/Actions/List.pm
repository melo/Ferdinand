package Ferdinand::Actions::List;
# ABSTRACT: a very cool module

use Ferdinand::Moose;
use Method::Signatures;
use Ferdinand::Utils 'render_template';
use namespace::clean -except => 'meta';

extends 'Ferdinand::Action';


method render ($ctx) {
  my $rows = $self->impl->fetch_rows($self, $ctx);

  return render_template(
    'list.pltj',
    { action    => $self,
      col_names => $self->column_names,
      cols      => $self->columns,
      rows      => $rows,
      ctx       => $ctx,
    }
  );
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ list.pltj
<?pl #@ARGS cols, col_names, rows, ctx ?>

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
<?pl if (@$rows) { ?>
<?pl   for my $row (@$rows) { ?>
    <tr>
<?pl
       for my $col (@$col_names) {
         my $ci = $cols->{$col};
         my $v = $row->{$col};
         $v = $ci->{formatter}->($v) if $ci->{formatter};
?>
<?pl       if (my $l = $ci->{linked}) { ?>
      <td><a href="[= $ctx->{uri_helper}->($l, $row->{_id}) =]">[= $v =]</a></td>
<?pl       } ?>
<?pl       elsif (my $l = $ci->{link_to}) { ?>
      <td><a href="[= $l->($row, $ctx) =]">[= $v =]</a></td>
<?pl       } ?>
<?pl       else { ?>
      <td>[= $v =]</td>
<?pl       } ?>
<?pl     } ?>
    </tr>
<?pl   } ?>
<?pl } ?>
<?pl else { my $n_cols = @$cols; ?>
    <tr colspan="[= $n_cols =]">Não existem registos para listar</tr>
<?pl } ?>
  </tbody>
</table>
