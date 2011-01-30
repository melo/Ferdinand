package Ferdinand::Widgets::Layout;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::WidgetContainer';

has 'overlay' => (isa => 'HashRef', is => 'ro', default => sub { {} });

after setup_fields => method ($fields) { push @$fields, 'overlay' };


method render_begin ($ctx) {
  my %o = %{$self->overlay};

  $o{id} = [$ctx->id] if $ctx->has_id && !exists $o{id};
  $o{set}   = $ctx->set   unless exists $o{set};
  $o{item}  = $ctx->item  unless exists $o{item};
  $o{model} = $ctx->model unless exists $o{model};

  if (exists $o{prefix}) {
    $o{params} = $ctx->params->{$o{prefix}} || {};
  }

  return $ctx->overlay(%o);
}


__PACKAGE__->meta->make_immutable;
1;
