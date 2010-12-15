package Ferdinand::Widgets::DBIC::Update;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';
with 'Ferdinand::Roles::DBICValidation';

method dbic_action ($ctx, $fields) {
  eval {
    $ctx->item->update($fields);
    $ctx->stash->{edit_done} = 1;
  };
  $ctx->add_error(exception => $@) if $@;
}


__PACKAGE__->meta->make_immutable;
1;
