package Ferdinand::Widgets::List::Add;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template);
use Carp 'confess';

extends 'Ferdinand::Widgets::List';
with 'Ferdinand::Roles::ListButtons', 'Ferdinand::Roles::WidgetContainer';

has 'form_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', shift->id, 'form') },
);

has 'form_visibility' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', shift->form_id, 'visibility') },
);

has 'btn_show_form_id' => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { join('_', 'btn', 'show_form', shift->id) },
);

after setup_attrs => method($class:, $attrs, $meta, $sys, $stash) {
  push @{$attrs->{btns_to_check}}, 'btn_show_form';
};


method render_self_write ($ctx, $elems, $id_map, $btns) {

  if ($ctx->params->{$self->form_visibility}) {
    my $guard = $ctx->overlay(prefix => $self->form_id, item => undef);
    $self->render_widgets($ctx);
    $ctx->buffer(render_template('form_ops.pltj', {ctx => $ctx}));
  }
  else {
    $ctx->buffer(render_template('no_form_ops.pltj', {ctx => $ctx}));
  }
}


method _btn_add_action ($ctx, $elems) {
  my $form_data = $ctx->params->{$self->form_id};
  
  ## TODO: Form/Source VALIDATION here - should be done by $ctx->model->validate($form_data);
  push @$elems, $form_data;
  $form_data->{__ACTION} = 'ADD';
  
  # if ($validation_not_ok) {
  #   # Keep visible to show errors
  #   $ctx->params->{$self->form_visibility} = 1;
  # }
}

method _btn_show_form_action ($ctx) {
  $ctx->params->{$self->form_visibility} = 1;
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ form_ops.pltj
<?pl #@ARGS ctx ?>
<?pl my $w = $ctx->widget; ?>

<div class="w_list_add_ops">
  <input type="submit" name="[= $w->btn_add_id =]" value="Adicionar">
</div>

@@ no_form_ops.pltj
<?pl #@ARGS ctx ?>
<?pl my $w = $ctx->widget; ?>

<div class="w_list_add_ops">
  <input type="submit" name="[= $w->btn_show_form_id =]" value="Adicionar">
</div>
