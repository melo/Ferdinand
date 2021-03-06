package Ferdinand::Model::DBIC;
# ABSTRACT: Ferdinand model for DBIx::Class sources

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw( hash_merge parse_structured_key );
use Method::Signatures;
extends 'Ferdinand::Model';

has 'source' => (
  is       => 'ro',
  isa      => 'DBIx::Class::ResultSource',
  required => 1,
  handles  => [qw(primary_columns columns)],
);

our %meta_types = (
  integer  => 'numeric',
  decimal  => 'numeric',
  tinyint  => 'numeric',
  varchar  => 'text',
  char     => 'text',
  text     => 'text',
  date     => 'date',
  datetime => 'date',
);


method fetch ($id, $source?) {
  $source = $self->source unless $source;

  $id = [$id] unless ref $id;
  return $source->resultset->find(@$id);
}


method id_for_item ($item) {
  return unless defined $item;

  if (ref($item) eq 'HASH') {
    return $item->{__ID} if exists $item->{__ID};
  }
  else {
    my @pk = $item->id;
    return $pk[0] if scalar(@pk) == 1;
    return \@pk;
  }

  return;
}


method column_meta_fixup ($full_name, $defs = {}, $source?) {
  my %info;
  $source ||= $self->source;

  ### Deal with nested fields
  my @path = parse_structured_key($full_name);
  my $name = shift @path;
  while (@path) {
    if ($source && !ref($name)) {
      if ($source->has_relationship($name)) {
        $source = $source->related_source($name);
      }
      else {
        $source = undef;
      }
    }
    $name = shift @path;
  }

  ### Enrich with DBIC meta-data
  if ($source && $source->has_column($name)) {
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
    $info{is_required} = !$info{is_nullable};

    for (qw( format formatter label width )) {
      $info{$_} = $ci->{extra}{$_}
        if exists $ci->{extra}{$_};
    }

    $info{default_value} = $ci->{extra}{default}
      if exists $ci->{extra}{default};

    if (exists $ci->{extra}{options}) {
      my $opts = $info{options} = [];

      for my $opt (@{$ci->{extra}{options}}) {
        $opt = {id => $opt, text => $opt} unless ref($opt) eq 'HASH';
        $opt->{text} = $opt->{id} unless $opt->{text};
        push @$opts, $opt;
      }
    }

    my $classes = $ci->{extra}{classes} || {};
    for my $t (keys %$classes) {
      my $cls = $classes->{$t};
      $cls = [$cls] unless ref $cls;
      $info{"cls_$t"} = $cls;
      $info{"cls_${t}_html"} =
        @$cls ? ' class="' . join(' ', @$cls) . '"' : '';
    }
  }

  if (!exists $info{label}) {
    my $label = $name;
    $label =~ s/_/ /g;
    $label =~ s/\b(\w)/uc($1)/ge;
    $label =~ s/\bId/ID/g;

    $info{label} = $label;
  }

  ### Merge user_overrides
  hash_merge(\%info, %$defs);

  ### General cleanups
  $info{is_required} = 0 unless exists $info{is_required};
  if (!exists $info{meta_type} && exists $info{data_type}) {
    my $t = $info{data_type};
    $info{meta_type} = exists $meta_types{$t} ? $meta_types{$t} : 'unknown';
  }

  return \%info;
}


__PACKAGE__->meta->make_immutable;
1;

=head1 DESCRIPTION

The L<Ferdinand::Impl::DBIC> class is a L<Ferdinand> implementation that
extracts all the required metadata from a given
L<DBIx::Class::ResultSource>.
