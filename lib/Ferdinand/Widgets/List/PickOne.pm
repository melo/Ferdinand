package Ferdinand::Widgets::List::PickOne;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template);
use Carp 'confess';

extends 'Ferdinand::Widgets::List';
with 'Ferdinand::Roles::ListButtons';

has 'options' => (isa => 'CodeRef', is => 'ro', required => 1);

has 'select_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', shift->id, 'new') },
);

after setup_fields => method($fields) {push @$fields, qw(options select_id)};


method render_self_write ($ctx, $elems, $id_map) {
  $ctx->buffer(
    render_template(
      'picker.pltj',
      { ctx     => $ctx,
        options => $self->_get_options($ctx, $id_map),
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

method _get_id ($ctx) {
  return $ctx->params->{$self->select_id};
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
</div>
