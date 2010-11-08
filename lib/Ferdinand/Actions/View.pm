package Ferdinand::Actions::View;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template new_context);

extends 'Ferdinand::Action';


method render ($ctx) {
  my $row = $self->impl->fetch_row($self, $ctx);
  return unless $row;

  $ctx = new_context($ctx, row => $row);
  return (
    title  => $self->page_title($ctx,      $row),
    output => render_template('view.pltj', $ctx),
  );
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ view.pltj
<?pl #@ARGS action, row ?>
<?pl my $cols = $action->columns; ?>
<?pl my $col_names = $action->column_names; ?>

<table cellspacing="1">   
	<colgroup>
		<col width="20%"></col>
		<col width="80%"></col>
	</colgroup>          
    <tbody>
<?pl  for my $col (@$col_names) {
        my $ci = $cols->{$col};
        my $html = $action->render_field(
         col      => $col,
         row      => $row,
         col_info => $ci,
         ctx      => $_context,
        );
?>
        <tr> 
            <th>[= $ci->{label} =]:</td> 
            <td>[== $html =]</td> 
        </tr>
<?pl  } ?>
    </tbody> 
</table>
