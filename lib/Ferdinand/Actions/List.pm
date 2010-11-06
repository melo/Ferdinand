package Ferdinand::Actions::List;
# ABSTRACT: a very cool module

use Ferdinand::Moose;
use Method::Signatures;
use Ferdinand::Utils 'render_template';
use namespace::clean -except => 'meta';

extends 'Ferdinand::Action';

has 'title' => ( isa => 'Str', is  => 'ro' );

has 'column_names' => (
  isa      => 'ArrayRef',
  is       => 'ro',
  required => 1,
);

has 'columns' => (
  isa      => 'HashRef',
  is       => 'ro',
  required => 1,
);


method setup ($class:, $meta) {
  my %clean;

  ## Remove known attributes
  for my $f (qw( title )) {
    $clean{$f} = delete $meta->{$f} if exists $meta->{$f};
  }

  ## Columns
  my $col_spec = delete($meta->{columns}) || [];
  confess "Action 'List' requires a 'columns' specification, "
    unless @$col_spec;

  my @col_order;
  my %col_meta;
  while (@$col_spec) {
    my $name = shift @$col_spec;
    my $info = ref($col_spec->[0]) eq 'HASH' ? shift @$col_spec : {};

    push @col_order, $name;
    $col_meta{$name} = $info;
  }

  return $class->new(
    %clean,
    column_names => \@col_order,
    columns      => \%col_meta,
  );
}


method render ($impl, $ctx) {
  my $rows = $impl->fetch_rows($self, $ctx);

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
<?pl for my $col (@$col_names) { ?>
      <th>[= $col =]</th>
<?pl } ?>
    </tr>
  </thead>
  <tbody>
<?pl if (@$rows) { ?>
<?pl   for my $row (@$rows) { ?>
    <tr>
<?pl     for my $col (@$col_names) { my $ci = $cols->{$col}; ?>
<?pl       if (my $l = $ci->{linked}) { ?>
      <td><a href="[= $ctx->{uri_helper}->($l, $row->{_id}) =]">[= $row->{$col} =]</a></td>
<?pl       } ?>
<?pl       elsif (my $l = $ci->{link_to}) { ?>
      <td><a href="[= $l->($row, $ctx) =]">[= $row->{$col} =]</a></td>
<?pl       } ?>
<?pl       else { ?>
      <td>[= $row->{$col} =]</td>
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
