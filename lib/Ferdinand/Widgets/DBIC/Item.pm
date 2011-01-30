package Ferdinand::Widgets::DBIC::Item;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'item'     => (isa => 'CodeRef', is => 'ro', required => 1);
has 'required' => (isa => 'Bool',    is => 'ro', default  => 1);

after setup_fields => method($fields) {push @$fields, qw(item required)};


method render_self ($ctx) {
  local $_ = $ctx;
  my $item = $self->item->($self, $ctx);

  $ctx->item($item), return if $item;
  $ctx->clear_item;
  return unless $self->required;

  my @id = $ctx->id;
  confess('Item not found (id ['
      . (@id ? join(', ', @id) : '<no id>')
      . '], source '
      . $ctx->model->source->source_name
      . ')');
}


__PACKAGE__->meta->make_immutable;
1;
