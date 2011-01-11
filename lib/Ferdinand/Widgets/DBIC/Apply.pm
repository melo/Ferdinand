package Ferdinand::Widgets::DBIC::Apply;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::DBICValidation';

method dbic_action ($ctx, $fields) {
  my $target = my $item = $ctx->item;
  $target ||= $ctx->set || $ctx->model->source->resultset;
  eval {
    $ctx->stash->{dbic_row} = $target->apply($fields, $item);
    $ctx->stash->{edit_done} = 1;
  };
  $ctx->add_error(exception => $@) if $@;
}


__PACKAGE__->meta->make_immutable;
1;
