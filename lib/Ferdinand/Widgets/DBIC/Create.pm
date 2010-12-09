package Ferdinand::Widgets::DBIC::Create;

# ABSTRACT: a very cool module

use Ferdinand::Setup 'class';
use Method::Signatures;

extends 'Ferdinand::Widget';

has 'valid' => (
  isa     => 'CodeRef',
  is      => 'ro',
  default => sub {
    sub { }
  },
);


method setup_attrs ($class:, $attrs, $meta) {
  for my $f (qw( valid )) {
    $attrs->{$f} = delete $meta->{$f} if exists $meta->{$f};
  }
}

method render_self ($ctx) {
  my $fields;
  if (my $valid = $self->valid) {
    local $_ = $ctx;
    $fields = $valid->($self);
  }
  return unless $fields && ref($fields) eq 'HASH';

  $self->_validate($ctx, $fields);
  return if $ctx->has_errors;

  eval {
    $ctx->stash->{dbic_row} = $ctx->model->source->resultset->create($fields);
  };
  $ctx->add_error(exception => $@);
}

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

method _validate ($ctx, $fields) {
  my $model = $ctx->model;
  my $src   = $model->source;

  for my $col ($src->columns) {
    next unless exists $fields->{$col};

    my $i    = $src->column_info($col);
    my $t    = $i->{data_type};
    my $mt   = $meta_types{$t};
    my $req  = !$i->{is_nullable};
    my $meta = $model->column_meta_fixup($col);

    my $v = $ctx->field_value_str($col, $meta, $fields);
    $v =~ s/^\s+|\s+$//g;

    if ($req && $mt eq 'text' && length($v) == 0) {
      $ctx->add_error($col => 'Campo obrigatório');
    }

    $fields->{$col} = $v;
  }
}


__PACKAGE__->meta->make_immutable;
1;
