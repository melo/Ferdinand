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

has 'btns_to_check' => (
  isa     => 'ArrayRef',
  is      => 'ro',
  default => sub { [] }
);

after setup_fields => method($fields) {
  push @$fields, qw( prefix btn_add_id btn_del_id btn_undel_id );
};

after setup_attrs => method($class:, $attrs, $meta, $sys, $stash) {
  push @{$attrs->{btns_to_check}}, 'btn_add', \'btn_del', \'btn_undel';
};


method render_self ($ctx) {
  my ($elems, $id_map, $btns) = $self->_process_buttons($ctx);
  $self->render_list($ctx, $elems);
  $self->render_per_mode($ctx, $elems, $id_map, $btns);
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
    if (exists $item->{__ID}) {
      push @actions, {__ID => $item->{__ID}, __ACTION => $action};
    }
    else {
      push @actions, $item;
    }
  }

  return serialize_structure({$self->prefix => \@actions});
}


method _process_buttons ($ctx) {
  my $elems = $self->_get_elems($ctx);
  my %id_map = map { $_->{__ID} => $_ } grep { exists $_->{__ID} } @$elems;
  my %btns_used;
  my $btns_to_check = $self->btns_to_check;

  for (@$btns_to_check) {
    my $btn = $_; ## local copy, not alias
    my @check_args;
    if (ref $btn) {
      $btn = $$btn;
      push @check_args, 1;
    }
    my $btn_id = "${btn}_id";
    unshift @check_args, $self->$btn_id();

    my $arg = $ctx->was_button_used(@check_args);
    next unless defined $arg;

    my $btn_action = "_${btn}_action";
    $self->$btn_action($ctx, $elems, \%id_map, $arg);

    $btns_used{$btn} = 1;
    last;    ## There can be only one ... button pressed
  }

  return ($elems, \%id_map, \%btns_used);
}

method _btn_add_action ($ctx, $elems, $id_map) {}

method _btn_del_action ($ctx, $elems, $id_map, $pos) {
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
