package Ferdinand::Action;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

with
  'Ferdinand::Roles::Setup',
  'Ferdinand::Roles::ColumnSet';

has 'title' => (isa => 'Str|CodeRef', is => 'ro');


method setup_attrs ($class:, $attrs, $impl, $meta) {
  ## Remove known attributes
  for my $f (qw( title )) {
    $attrs->{$f} = delete $meta->{$f} if exists $meta->{$f};
  }
}


method page_title ($ctx, $r?) {
  my $title = $self->title;
  $title = $title->($ctx, $r) if ref $title;

  return $title;
}


__PACKAGE__->meta->make_immutable;
1;
