package Ferdinand;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw( load_class load_widget expand_structure );
use Carp 'confess';
use Method::Signatures;

sub map_class_name     {'Ferdinand::Map'}
sub action_class_name  {'Ferdinand::Action'}
sub context_class_name {'Ferdinand::Context'}


method setup ($sys:, $class, $meta) {
  my %stash;
  load_class($class);
  my $obj = $class->setup($meta, $sys, \%stash);

  my $ctx = $sys->build_ctx({mode => 'setup', stash => \%stash});
  $obj->setup_check($ctx);

  confess('Could not parse attribures during $class setup: '
      . join(', ', sort keys %$meta))
    if %$meta;

  return $obj;
}


method setup_map ($sys:, $meta) {
  return $sys->setup($sys->map_class_name, $meta);
}


method render ($obj, $args = {}) {
  my $ctx = $self->build_ctx($args);
  $obj->render($ctx);

  my $mode = $ctx->mode;
  if ($ctx->has_errors && $mode =~ /^(.+)_do$/) {
    $mode = $1;
    my $g = $ctx->overlay(mode => $mode);
    $ctx->clear_buffer;
    $obj->render($ctx);
  }

  return $ctx;
}


method build_ctx ($attrs = {}) {
  $attrs->{params} = expand_structure($attrs->{params})
    if exists $attrs->{params};

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

