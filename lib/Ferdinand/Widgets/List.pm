package Ferdinand::Widgets::List;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template);
use Carp 'confess';

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::ColumnSet', 'Ferdinand::Roles::Title';

has 'create_label' => (isa => 'Str', is => 'ro');

method setup_attrs ($class:, $attrs, $meta) {
  $attrs->{create_label} = delete $meta->{create_label}
    if exists $meta->{create_label};
}


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
<?pl my $widget = $ctx->widget; ?>
<?pl my $cols = $widget->col_meta; ?>
<?pl my $col_names = $widget->col_names; ?>
<?pl my @rows = $ctx->set->all; ?>

<?pl if (my $cl = $widget->create_label) { ?>
<div class="oplinks">
  <ul>
    <li><a href="[= $ctx->uri('create') =]">[= $cl =]</a></li>
  </ul>
</div>
<?pl } ?>

<?pl if (my $title = $widget->title($ctx)) { ?>
<h1>[= $title =]</h1>
<?pl } ?>

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
<?pl  if (@rows) { ?>
<?pl    for my $row (@rows) { ?>
    <tr>
<?pl      for my $col (@$col_names) {
            my $html = $ctx->render_field(
              item  => $row,
              field => $col,
              meta  => $cols->{$col},
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
