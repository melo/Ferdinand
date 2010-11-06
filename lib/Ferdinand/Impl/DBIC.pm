package Ferdinand::Impl::DBIC;
# ABSTRACT: Ferdinand Implementation for DBIx::Class Result Sources

use Ferdinand::Moose;
use Method::Signatures;
use namespace::clean -except => 'meta';

extends 'Ferdinand::Impl';

has 'source' => ( isa => 'DBIx::Class::ResultSource', is  => 'ro', required => 1);

method setup ($class:, $meta) {
  my %fields;
  for my $f (qw( source )) {
    $fields{$f} = delete $meta->{$f};
  }
  
  return $class->new(\%fields);
}


method column_meta_fixup ($name, $info) {
  my $ci = $self->source->column_info($name);
  return unless $ci;

  $info->{formatter} = $ci->{extra}{formatter}
    if exists $ci->{extra}{formatter};
  
  my $label = $name;
  if (exists $ci->{extra}{label}) {
    $label = $ci->{extra}{label};
  }
  else {
    if ($name =~ m/_id$/) {
      $label = 'ID';
    }
    else {
      $label = $name;
      $label =~ s/_/ /g;
      $label =~ s/\b(\w)/uc($1)/ge;
    }
  }
  $info->{label} = $label;

  my $classes = $ci->{extra}{classes} || {};
  for my $t (qw(list)) {
    my $cls = $classes->{$t} || [];
    $cls = [$cls] unless ref $cls;
    $info->{"cls_$t"} = $cls;
    $info->{"cls_${t}_html"} = @$cls? ' class="' . join(' ', @$cls) . '"' : '';
  }
}


method fetch_rows ($action, $ctx) {
  my $cols = $action->columns;
  ## TODO: how to let $ctx influence the resultset?
  my @rows = $self->source->resultset->all;
  for my $r (@rows) {
    my %info = (_id => $r->id, _row => $r);
    for my $col (keys %$cols) {
      $info{$col} = $r->$col();
    }
    $r = \%info;
  }

  return \@rows;
}


__PACKAGE__->meta->make_immutable;
1;

=head1 DESCRIPTION

The L<Ferdinand::Impl::DBIC> class is a L<Ferdinand> implementation that
extracts all the required metadata from a given
L<DBIx::Class::ResultSource>.
