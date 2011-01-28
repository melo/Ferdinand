package Ferdinand::Widgets::List::PickOne;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils
  qw(render_template find_structure serialize_structure empty );
use Carp 'confess';

extends 'Ferdinand::Widgets::List';

has 'prefix'  => (isa => 'Str',     is => 'ro', required => 1);
has 'sufix'   => (isa => 'Str',     is => 'ro');
has 'options' => (isa => 'CodeRef', is => 'ro', required => 1);

has 'select_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', shift->id, 'new') },
);

has 'btn_add_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', 'btn', 'add', shift->select_id) },
);

after setup_fields => method($fields) {
  push @$fields, qw(prefix sufix options select_id btn_add_id);
};


method render_self ($ctx) {
  my ($elems, $state, $id_map) = $self->_process_buttons($ctx);
  $self->render_list($ctx, $elems);
  $self->render_per_mode($ctx, $state, $id_map);
}

method render_self_write ($ctx, $state, $id_map) {
  $ctx->buffer(
    render_template(
      'picker.pltj',
      { ctx     => $ctx,
        options => $self->_get_options($ctx, $id_map),
        state   => $state,
      }
    )
  );
}

method _get_options ($ctx, $id_map) {
  local $_ = $ctx;
  my $opts = $self->options->($self);
  $opts = [grep { !exists $id_map->{$_->{id}} } @$opts];

  return $opts;
}

method _process_buttons ($ctx) {
  my $params = $ctx->params;
  my $elems  = $self->_get_elems($ctx);
  my %id_map = map { $_->{__ID} => $_ } grep { exists $_->{__ID} } @$elems;

  ## add item
  if ($params->{$self->btn_add_id}) {
    my $id = $params->{$self->select_id};
    if (!empty($id) && !exists $id_map{$id}) {
      my $item = $ctx->model->fetch($id);
      if ($item) {
        $item = $self->_get_columns_from_item($ctx, $item);
        $item->{__ADD} = $id;
        $id_map{$id} = $item;

        push @$elems, $item;
      }
    }
  }

  my @state;
  for my $item (@$elems) {
    if (exists $item->{__ADD}) { push @state, {__ID => $item->{__ADD}} }
  }

  return ($elems, serialize_structure({$self->prefix => \@state}), \%id_map);
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ picker.pltj
<?pl #@ARGS ctx, options, state ?>
<?pl my $w = $ctx->widget; ?>

<div class="w_pickone">
  <select name="[= $w->select_id =]">
<?pl push @$options, { id => '', text => '-- Vazio --' } unless @$options; ?>
<?pl for (@$options) { ?>
    <option value="[= $_->{id} =]">[= $_->{text} =]</option>
<?pl } ?>
  </select>
  <input type="submit" name="[= $w->btn_add_id =]" value="Adicionar">

<?pl while (my ($k, $v) = each %$state) { ?>
  <input type="hidden" name="[= $k =]" value="[= $v =]">
<?pl } ?>
</div>
