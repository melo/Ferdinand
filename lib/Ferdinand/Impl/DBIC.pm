package Ferdinand::Impl::DBIC;
# ABSTRACT: Ferdinand Implementation for DBIx::Class Result Sources

use Ferdinand::Setup 'class';
use Method::Signatures;

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
  my $cols = $action->column_names;

  ## TODO: how to let $ctx influence the resultset?
  my @rows = $self->source->resultset->all;
  map { $_ = _load_row($_, $cols) } @rows;

  return \@rows;
}


method fetch_row ($action, $ctx) {
  my $row = $self->source->resultset->find(@{$ctx->{id}});
  return unless $row;

  return _load_row($row, $action->column_names);
}


func _load_row ($r, $cols) {
  my %info = (_id => $r->id, _row => $r);
  for my $col (@$cols) {
    $info{$col} = $r->$col();
  }

  return \%info;
}


__PACKAGE__->meta->make_immutable;
1;

=head1 DESCRIPTION

The L<Ferdinand::Impl::DBIC> class is a L<Ferdinand> implementation that
extracts all the required metadata from a given
L<DBIx::Class::ResultSource>.
