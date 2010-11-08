package Ferdinand::Action;
# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw( ehtml ghtml );
use Method::Signatures;

with 'Ferdinand::Roles::ColumnSet';


has 'impl' => (isa => 'Ferdinand::Impl', is => 'ro', required => 1);
has 'title' => (isa => 'Str|CodeRef', is => 'ro');


method setup ($class:, $impl, $meta) {
  $class->setup_attrs(\my %attrs, @_);
  return $class->new(%attrs, impl => $impl);
}


method setup_attrs ($class:, $attrs, $impl, $meta) {
  ## Remove known attributes
  for my $f (qw( title )) {
    $attrs->{$f} = delete $meta->{$f} if exists $meta->{$f};
  }
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


method page_title ($ctx, $r?) {
  my $title = $self->title;
  $title = $title->($ctx, $r) if ref $title;

  return $title;
}


__PACKAGE__->meta->make_immutable;
1;
