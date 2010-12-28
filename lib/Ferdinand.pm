package Ferdinand;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Carp 'confess';
use Method::Signatures;

sub map_class_name     {'Ferdinand::Map'}
sub action_class_name  {'Ferdinand::Action'}
sub context_class_name {'Ferdinand::Context'}

method setup($class:, :$meta, :$map_class) {
  ## Pick our implementation class
  $map_class = $class->map_class_name unless $map_class;
  eval "require $map_class";
  confess($@) if $@;

  ## Let our implementation parse the specification
  my $self = $map_class->setup($meta, $class);

  confess('Could not understand attribures: ' . join(', ', sort keys %$meta))
    if %$meta;

  return $self;
}

method build_ctx ($attrs = {}) {
  return $self->context_class_name->new($attrs);
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

