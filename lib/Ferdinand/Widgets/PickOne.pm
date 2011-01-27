package Ferdinand::Widgets::PickOne;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template find_structure);
use Carp 'confess';

extends 'Ferdinand::Widget';

has 'prefix' => (isa => 'Str',            is => 'ro', required => 1);
has 'column' => (isa => 'Str',            is => 'ro', required => 1);
has 'set'    => (isa => 'CodeRef', is => 'ro', required => 1);

after setup_fields => method ($fields) {push @$fields, qw(prefix column set)};


method render_self_write ($ctx) {
  my $select_id = $self->id . '_new';

  my $set = $self->_get_set($ctx);
  my $rows = $self->_get_options($ctx, $set);
  my $elems = $self->_get_elements($ctx, $set, $select_id);

  $ctx->buffer(
    render_template(
      'picker.pltj',
      { ctx       => $ctx,
        rows      => $rows,
        elems     => $elems,
        prefix    => $self->prefix,
        select_id => $select_id,
      }
    )
  );
}

method _get_set ($ctx) {
  my $set = $self->set;

  local $_ = $ctx;
  $set = $set->($self);

  return $set;
}

method _get_options ($ctx, $set) {
  my $column = $self->column;

  return [map { {id => $_->id, text => $_->$column} } $set->all];
}

method _get_elements ($ctx, $set, $select_id) {
  my $params = $ctx->params;
  my $prefix = $self->prefix;
  my $elems  = find_structure($params, $prefix) || [];

  if ($params->{"btn_$select_id"}) {
    my ($col, $trouble) = $set->result_source->primary_columns;
    confess("PickOne needs ResultSources with a single column primary key, ")
      if $trouble;

    push @$elems, {$col => $params->{$select_id}};
  }

  return $elems;
}




__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ picker.pltj
<?pl #@ARGS ctx, rows, prefix, select_id, elems ?>
<div class="w_pickone">
  <select name="[= $select_id =]">
<?pl for (@$rows) { ?>
    <option value="[= $_->{id} =]">[= $_->{text} =]</option>
<?pl } ?>
  </select>
  <input type="submit" name="btn_[= $select_id =]" value="Adicionar">

<?pl
  my $i = 0; for my $item (@$elems) {
    for my $k (keys %$item) {
?>
  <input type="hidden" name="[= "${prefix}[${i}].${k}" =]" value="[= $item->{$k} =]">
<?pl
    }
    $i++;
  }
?>
</div>
