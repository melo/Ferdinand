package Ferdinand::Widgets::List;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template find_structure serialize_structure);
use Carp 'confess';

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::ColumnSet', 'Ferdinand::Roles::Title';

method render_self ($ctx) {
  $self->render_list($ctx, $self->_get_elems($ctx));
}

method render_list ($ctx, $elems) {
  $elems = serialize_structure($elems);
  my $state = serialize_structure({$self->id => {i => 1, e => $elems}});

  my $col_names = [@{$self->col_names}];
  $self->_add_ops_column($ctx, $elems, $col_names)
    if $self->_has_ops_column($ctx);

  $ctx->buffer(
    render_template(
      'list.pltj',
      { ctx       => $ctx,
        elems     => $elems,
        state     => $state,
        col_names => $col_names,
      }
    )
  );
}

method _get_elems ($ctx) {
  my $id = $self->id;
  my $p  = $ctx->params;

  my $elems;
  if (find_structure($p, "${id}.i")) {
    $elems = find_structure($p, "${id}.e");
  }
  elsif (my $rs = $ctx->set) {
    while (my $row = $rs->next) {
      push @$elems, $self->_get_columns_from_item($ctx, $row);
    }
  }

  return $elems || [];
}


method _has_ops_column ($ctx) { return 0}
method _get_ops_column ($ctx, $item, $n) {}

method _add_ops_column ($ctx, $elems, $col_names) {
  my $c = 0;
  for my $item (@$elems) {
    my $ops = $self->_get_ops_column($ctx, $item, $c++);
    $item->{ops} = $ops || '';
  }
  push @$col_names, 'ops';
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ list.pltj
<?pl #@ARGS ctx, elems, col_names, state ?>
<?pl my $model = $ctx->model; ?>

[== $ctx->widget->render_title($ctx, {class => "w_list"}) =]

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
<?pl   for my $row (@$elems) { my $class = $row->{__META}{class}; ?>
<?pl     if ($class) { ?>
    <tr class="[= $class =]">
<?pl     } else { ?>
    <tr>
<?pl     } ?>
<?pl     for my $col (@$col_names) { ?>
      <td>[== $row->{$col} =]</td>
<?pl     } ?>
    </tr>
<?pl   } ?>
<?pl } ?>
<?pl else { ?>
    <tr><td colspan="[= scalar(@$col_names) =]">Não existem registos para listar</td></tr>
<?pl } ?>
  </tbody>
</table>

<?pl if ($ctx->is_mode_write) { ?>
<?pl   while (my ($k, $v) = each %$state) { ?>
<input type="hidden" name="[= $k =]" value="[= $v =]">
<?pl   } ?>
<?pl } ?>
