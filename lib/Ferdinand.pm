package Ferdinand;
# ABSTRACT: a very cool module

use Ferdinand::Moose;
use Ferdinand::Impl::DBIC;
use Method::Signatures;
use namespace::clean -except => 'meta';

method setup($class:, $meta) {
  ## Pick our implementation class
  $class = delete($meta->{impl}) || _pick_implementation($meta);

  ## Let our implementation parse the specification
  my $self = $class->setup($meta);
  $self->setup_actions($meta);

  confess('Could not understand attribures: ' . join(', ', sort keys %$meta))
    if %$meta;

  return $self;
}


## TODO: move this to a plugin system in the Ferdinand::SourceTypes::* namespace
func _pick_implementation ($meta) {
  my $source = $meta->{source};
  confess "No source found, "
    unless $source;
  
  return 'Ferdinand::Impl::DBIC' if $source->isa('DBIx::Class::ResultSource');
  confess "Could not determine implementation class for '$source', ";
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

Ferdinand is a basic CRUD system.

You create a Ferdinand object using the C<setup> constructor. It accepts
a hash with options. The first thing it will do is detect which backend
implementation of Ferdinand will we use. Right now, we only support
L<DBIx::Class> so we require a C<source> option with the
L<DBIx::Class::ResultSource> to use.

The implementation will extract other fields it requires from the hash.
The rest of the fields remaining after that are matched to CRUD actions:
C<list>, C<show>, C<create>, and C<edit>.

