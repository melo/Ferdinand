package Ferdinand::Roles::ListButtons;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'role';
use Method::Signatures;
use Ferdinand::Utils qw(render_template serialize_structure ghtml );
use Carp 'confess';

has 'prefix' => (isa => 'Str', is => 'ro', required => 1);

has 'btn_add_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', 'btn', 'add', shift->id) },
);

has 'btn_del_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', 'btn', 'del', shift->id) },
);

has 'btn_undel_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', 'btn', 'undel', shift->id) },
);

after setup_fields => method($fields) {
  push @$fields, qw( prefix btn_add_id btn_del_id btn_undel_id );
};


method render_self ($ctx) {
  my ($elems, $id_map) = $self->_process_buttons($ctx);
  $self->render_list($ctx, $elems);
  $self->render_per_mode($ctx, $elems, $id_map);
}

after 'render_self_write' => method($ctx, $elems) {
  $ctx->buffer(
    render_template(
      'state.pltj',
      { ctx     => $ctx,
        actions => $self->_get_actions($ctx, $elems),
      }
    )
  );
};

method _get_actions ($ctx, $elems) {
  my @actions;
  for my $item (@$elems) {
    next unless my $action = $item->{__ACTION};
    push @actions, {__ID => $item->{__ID}, __ACTION => $action};
  }

  return serialize_structure({$self->prefix => \@actions});
}


method _process_buttons ($ctx) {
  my $elems = $self->_get_elems($ctx);
  my %id_map = map { $_->{__ID} => $_ } grep { exists $_->{__ID} } @$elems;

  ## add item
  if ($ctx->was_button_used($self->btn_add_id)) {
    $self->_btn_add_action($ctx, $elems, \%id_map);
  }

  ## del item
  elsif (defined(my $pos_d = $ctx->was_button_used($self->btn_del_id, 1))) {
    $self->_btn_del_action($ctx, $elems, \%id_map, $pos_d);
  }

  ## undel item
  elsif (defined(my $pos_u = $ctx->was_button_used($self->btn_undel_id, 1))) {
    $self->_btn_undel_action($ctx, $elems, \%id_map, $pos_u);
  }

  return ($elems, \%id_map);
}

method _btn_add_action   ($ctx, $elems, $id_map) {}

method _btn_del_action   ($ctx, $elems, $id_map, $pos) {
  my $item = $elems->[$pos];
  if ($item) {
    my $action = $item->{__ACTION} || '';
    if (!$action) { $action = 'DEL' }
    elsif ($action eq 'ADD') { $action = 'IGN' }
    $item->{__ACTION} = $action;
  }
}

method _btn_undel_action ($ctx, $elems, $id_map, $pos) {
  my $item = $elems->[$pos];
  if ($item) {
    my $action = delete $item->{__ACTION};
    if ($action && $action eq 'IGN') { $item->{__ACTION} = 'ADD' }
  }
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


1;

__DATA__

@@ state.pltj
<?pl #@ARGS actions ?>

<div class="w_state">
<?pl while (my ($k, $v) = each %$actions) { ?>
  <input type="hidden" name="[= $k =]" value="[= $v =]">
<?pl } ?>
</div>
