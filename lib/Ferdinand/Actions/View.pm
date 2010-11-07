package Ferdinand::Actions::View;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils 'render_template';

extends 'Ferdinand::Action';


method render ($ctx) {
  my $row = $self->impl->fetch_row($self, $ctx);
  return unless $row;

  return (
    title  => $self->page_title($ctx, $row),
    output => render_template(
      'view.pltj',
      { action    => $self,
        col_names => $self->column_names,
        cols      => $self->columns,
        row       => $row,
        ctx       => $ctx,
      }
    )
  );
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ view.pltj
<?pl #@ARGS action, cols, col_names, row, ctx ?>

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
         ctx      => $ctx,
        );
?>
        <tr> 
            <th>[= $ci->{label} =]:</td> 
            <td>[== $html =]</td> 
        </tr>
<?pl  } ?>
    </tbody> 
</table>
