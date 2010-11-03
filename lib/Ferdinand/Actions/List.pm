package Ferdinand::Actions::List;
# ABSTRACT: a very cool module

use Ferdinand::Moose;
use Method::Signatures;
use namespace::clean -except => 'meta';

extends 'Ferdinand::Action';

has 'title' => ( isa => 'Str', is  => 'ro' );

has 'column_names' => (
  isa      => 'ArrayRef',
  is       => 'ro',
  required => 1,
);

has 'columns' => (
  isa      => 'HashRef',
  is       => 'ro',
  required => 1,
);


method setup ($class:, $meta) {
  my %clean;

  ## Remove known attributes
  for my $f (qw( title )) {
    $clean{$f} = delete $meta->{$f} if exists $meta->{$f};
  }

  ## Columns
  my $col_spec = delete($meta->{columns}) || [];
  confess "Action 'List' requires a 'columns' specification, "
    unless @$col_spec;

  my @col_order;
  my %col_meta;
  while (@$col_spec) {
    my $name = shift @$col_spec;
    my $info = ref($col_spec->[0]) eq 'HASH' ? shift @$col_spec : {};

    push @col_order, $name;
    $col_meta{$name} = $info;
  }

  return $class->new(
    %clean,
    column_names => \@col_order,
    columns      => \%col_meta,
  );
}


method render ($params) {
  return 'Listed!'
}


__PACKAGE__->meta->make_immutable;
1;


__DATA__
  title => 'Artigos',
  columns => [
    artigo_id => { linked => 'view' },
    titulo    => { linked => 'view' },

    slug => {
      link_to => sub {
        my ($c, $i) = @_;
        
        ## FIXME: move URI creation to Root::auto, stash it, use it here
        ## return $c->stash->{uri}->cat_not_artigo($item);
        return 'http://www.stage.e5.evolui.com/noticias/'.$i->slug
      },
    },
    
    'publicado_em',
    'visibilidade',
  ],
