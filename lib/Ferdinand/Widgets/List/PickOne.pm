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

has 'btn_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', 'btn', shift->select_id) },
);

after setup_fields => method($fields) {
  push @$fields, qw(prefix sufix options select_id btn_id);
};


method render_self ($ctx) {
  $self->render_list($ctx);
  $self->render_per_mode($ctx);
}

method render_self_write ($ctx) {
  $ctx->buffer(
    render_template(
      'picker.pltj',
      { ctx       => $ctx,
        elems     => $self->_get_elements($ctx),
        options   => $self->_get_options($ctx),
      }
    )
  );
}

method _get_options ($ctx) {
  local $_ = $ctx;
  return $self->options->($self);
}

method _get_elements ($ctx) {
  my $params = $ctx->params;
  my $prefix = $self->prefix;
  my $elems  = find_structure($params, $prefix);

  if ($params->{$self->btn_id}) {
    my $id = $params->{$self->select_id};
    if (!empty($id)) {
      my $elem = {__ID => $id};
      if (my $sufix = $self->sufix) {
        $elem = {$sufix => $elem};
      }
      push @$elems, $elem;
    }
  }

  return serialize_structure({ $prefix => $elems }) if $elems && @$elems;
  return {};
}



__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ picker.pltj
<?pl #@ARGS ctx, elems, options ?>
<?pl my $w = $ctx->widget; ?>
<?pl my $prefix = $w->prefix; ?>

<div class="w_pickone">
  <select name="[= $w->select_id =]">
<?pl for (@$options) { ?>
    <option value="[= $_->{id} =]">[= $_->{text} =]</option>
<?pl } ?>
  </select>
  <input type="submit" name="[= $w->btn_id =]" value="Adicionar">

<?pl while (my ($k, $v) = each %$elems) { ?>
  <input type="hidden" name="[= $k =]" value="[= $v =]">
<?pl } ?>
</div>
