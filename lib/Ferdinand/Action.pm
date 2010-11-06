package Ferdinand::Action;
# ABSTRACT: a very cool module

use Ferdinand::Moose;
use Ferdinand::Utils qw( ehtml ghtml );
use Method::Signatures;
use namespace::clean -except => 'meta';

has 'impl' => (isa => 'Ferdinand::Impl', is => 'ro', required => 1);

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


method setup ($class:, $impl, $meta) {
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
    
    $impl->column_meta_fixup($name, $info);
  }

  return $class->new(
    %clean,
    column_names => \@col_order,
    columns      => \%col_meta,
    impl         => $impl,
  );
}

method render_field (:$col, :$ctx, :$row, :$col_info) {
  my $v = $row->{$col};
  $v = $col_info->{formatter}->($v) if $col_info->{formatter};

  my $url;
  if ($url = $col_info->{linked}) {
    $url = $ctx->{uri_helper}->($url, $row->{_id});
  }
  elsif ($url = $col_info->{link_to}) {
    $url = $url->($row, $ctx);
  }

  if ($url) {
    $v = ghtml()->a({href => $url}, $v);
  }
  else {
    $v = ehtml($v);
  }

  return $v;
}



__PACKAGE__->meta->make_immutable;
1;
