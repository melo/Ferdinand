package Ferdinand::Widgets::DBIC::Create;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::DBICValidation';

method dbic_action ($ctx, $fields) {
  eval {
    $ctx->stash->{dbic_row} = $ctx->model->source->resultset->create($fields);
  };
  $ctx->add_error(exception => $@) if $@;
}


__PACKAGE__->meta->make_immutable;
1;
