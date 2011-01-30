package Ferdinand::Widgets::List::PickOne;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils
  qw(render_template find_structure serialize_structure empty ghtml );
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

has 'btn_del_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', 'btn', 'del', shift->select_id) },
);

has 'btn_undel_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', 'btn', 'undel', shift->select_id) },
);

after setup_fields => method($fields) {
  push @$fields, qw(
    prefix sufix options
    select_id
    btn_add_id btn_del_id btn_undel_id
  );
};


method render_self ($ctx) {
  my ($elems, $id_map) = $self->_process_buttons($ctx);
  $self->render_list($ctx, $elems);
  $self->render_per_mode($ctx, $elems, $id_map);
}

method render_self_write ($ctx, $elems, $id_map) {
  my $actions = $self->_get_actions($ctx, $elems);
  $ctx->buffer(
    render_template(
      'picker.pltj',
      { ctx     => $ctx,
        options => $self->_get_options($ctx, $id_map),
        actions   => $actions,
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

method _get_actions ($ctx, $elems) {
  my @actions;
  for my $item (@$elems) {
    next unless my $action = $item->{__ACTION};
    push @actions, {__ID => $item->{__ID}, __ACTION => $action};
  }

  return serialize_structure({$self->prefix => \@actions});
}


method _process_buttons ($ctx) {
  my $params = $ctx->params;
  my $elems  = $self->_get_elems($ctx);
  my %id_map = map { $_->{__ID} => $_ } grep { exists $_->{__ID} } @$elems;

  ## add item
  if ($ctx->was_button_used($self->btn_add_id)) {
    my $id = $params->{$self->select_id};
    if (!empty($id) && !exists $id_map{$id}) {
      my $item = $ctx->model->fetch($id);
      if ($item) {
        $item = $self->_get_columns_from_item($ctx, $item);
        $id_map{$id} = $item->{__ID};
        push @$elems, $item;
      }
      $item->{__ACTION} = 'ADD' if $item;
    }
  }

  ## del item
  elsif (defined(my $pos_d = $ctx->was_button_used($self->btn_del_id, 1))) {
    my $item = $elems->[$pos_d];
    if ($item) {
      my $action = $item->{__ACTION} || '';
      if (!$action) { $action = 'DEL' }
      elsif ($action eq 'ADD') { $action = 'IGN' }
      $item->{__ACTION} = $action;
    }
  }

  ## undel item
  elsif (defined(my $pos_u = $ctx->was_button_used($self->btn_undel_id, 1))) {
    my $item = $elems->[$pos_u];
    if ($item) {
      my $action = delete $item->{__ACTION};
      if ($action && $action eq 'IGN') { $item->{__ACTION} = 'ADD' }
    }
  }

  return ($elems, \%id_map);
}


method _has_ops_column { return 1 }
method _get_ops_column ($ctx, $item, $n) {
  my $h = ghtml();
  my $action = $item->{__ACTION} || '';

  $item->{__META}{class} = 'item_added' if $action eq 'ADD';
  return $h->input(
    { name  => join('_', $self->btn_del_id, $n),
      value => 'Remover',
      type  => 'submit'
    }
  ) if !$action || $action eq 'ADD';

  $item->{__META}{class} = 'item_removed';
  return $h->input(
    { name  => join('_', $self->btn_undel_id, $n),
      value => 'Adicionar',
      type  => 'submit'
    }
  );
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ picker.pltj
<?pl #@ARGS ctx, options, actions ?>
<?pl my $w = $ctx->widget; ?>

<div class="w_pickone">
  <select name="[= $w->select_id =]">
<?pl push @$options, { id => '', text => '-- Vazio --' } unless @$options; ?>
<?pl for (@$options) { ?>
    <option value="[= $_->{id} =]">[= $_->{text} =]</option>
<?pl } ?>
  </select>
  <input type="submit" name="[= $w->btn_add_id =]" value="Adicionar">

<?pl while (my ($k, $v) = each %$actions) { ?>
  <input type="hidden" name="[= $k =]" value="[= $v =]">
<?pl } ?>
</div>
