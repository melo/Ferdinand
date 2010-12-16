package Ferdinand::Model::DBIC;
# ABSTRACT: Ferdinand model for DBIx::Class sources

use Ferdinand::Setup 'class';
use Method::Signatures;
extends 'Ferdinand::Model';

has 'source' => (
  is       => 'ro',
  isa      => 'DBIx::Class::ResultSource',
  required => 1,
);


method column_meta_fixup ($name, $defs = {}) {
  my %info   = %$defs;
  my $source = $self->source;
  return \%info unless $source->has_column($name);

  my $ci = $source->column_info($name);

  my @fields = qw(
    data_type
    size
    is_nullable
    is_currency is_uri
    default_value
    currency_code
  );

  for my $f (@fields) {
    $info{$f} = $ci->{$f} if exists $ci->{$f};
  }

  $info{format} = $ci->{extra}{format}
    if exists $ci->{extra}{format};

  $info{formatter} = $ci->{extra}{formatter}
    if exists $ci->{extra}{formatter};

  $info{options} = $ci->{extra}{options}
    if exists $ci->{extra}{options};

  my $label = $name;
  if (exists $ci->{extra}{label}) {
    $label = $ci->{extra}{label};
  }
  else {
    $label = $name;
    $label =~ s/_/ /g;
    $label =~ s/\b(\w)/uc($1)/ge;
    $label =~ s/\bId/ID/g;
  }
  $info{label} = $label;

  my $classes = $ci->{extra}{classes} || {};
  for my $t (keys %$classes) {
    my $cls = $classes->{$t};
    $cls = [$cls] unless ref $cls;
    $info{"cls_$t"} = $cls;
    $info{"cls_${t}_html"} = @$cls ? ' class="' . join(' ', @$cls) . '"' : '';
  }

  if (my $df = $ci->{extra}{default}) {
    $info{default_value} = $df;
  }

  return \%info;
}


__PACKAGE__->meta->make_immutable;
1;

=head1 DESCRIPTION

The L<Ferdinand::Impl::DBIC> class is a L<Ferdinand> implementation that
extracts all the required metadata from a given
L<DBIx::Class::ResultSource>.
