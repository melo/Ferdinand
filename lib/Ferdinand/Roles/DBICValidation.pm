package Ferdinand::Roles::DBICValidation;

use Ferdinand::Setup 'role';
use Method::Signatures;
use Ferdinand::Utils qw(hash_select hash_grep empty);
use DateTime::Format::MySQL;

requires 'dbic_action';

has 'valid' => (
  isa     => 'CodeRef',
  is      => 'ro',
  default => sub {
    sub { }
  },
);

after setup_fields => method ($fields) { push @$fields, 'valid' };


after render_self => method ($ctx) {
  my $fields = hash_grep { !/^btn_/ } $ctx->params;
  if (my $valid = $self->valid) {
    local $_ = $ctx;
    $fields = $valid->($self, $fields);
  }
  return unless $fields && ref($fields) eq 'HASH';

  $self->_validate($ctx, $fields);
  return if $ctx->has_errors;

  $self->dbic_action($ctx, $fields);
};

method _validate ($ctx, $fields) {
  my $model = $ctx->model;

  for my $col ($model->columns) {
    next unless exists $fields->{$col};

    my $meta = $model->field_meta($col);
    my $t    = $meta->{data_type};
    my $mt   = $meta->{meta_type};
    my $req  = $meta->{is_required};

    my $fv = $ctx->field_value_str(field => $col, item => $fields);
    my $v = $fv->[3];
    $v =~ s/^\s+|\s+$//g;
    my $is_empty = empty($v);

    if ($meta->{skip_if_empty} && $is_empty) {
      delete $fields->{$col};
      next;
    }

    if ($req && $mt eq 'text' && $is_empty) {
      $ctx->add_error($col => 'Campo obrigatório');
    }

    if (!$is_empty && $t eq 'datetime') {
      $v =~ s{/}{-}g;
      eval { $v = DateTime::Format::MySQL->parse_datetime($v) };
      $ctx->add_error($col => "Data/Hora inválida ($@)") if $@;
    }

    if (!$is_empty && $t eq 'date') {
      $v =~ s{/}{-}g;
      eval { $v = DateTime::Format::MySQL->parse_date($v) };
      $ctx->add_error($col => "Data inválida ($@)") if $@;
    }

    $fields->{$col} = $v;
  }

  $self->_check_db_restrictions($ctx, $fields);
}

method _check_db_restrictions($ctx, $fields) {
  my $src  = $ctx->model->source;
  my %un   = $src->unique_constraints;
  my @ours = _extract_pk_values_from_item($ctx);

  for my $name (keys %un) {
    my $flds = $un{$name};

    ### Skip if we don't have the fields to check this constraint
    my $sel = hash_select($fields, @$flds);
    next unless scalar(@$flds) == scalar(keys %$sel);

    ### Skip is no other row was found with the same fields
    my $row_found = $src->resultset->single($sel);
    next unless $row_found;

    ### If another row was found, skip if its the same as ours
    if (@ours) {
      my @other = _extract_pk_values_from_item($ctx, $row_found);
      next if @ours ~~ @other;
    }

    $ctx->add_error($_, "Elemento duplicado ($name)") for @$flds;
    last;
  }
}

func _extract_pk_values_from_item ($ctx, $item?) {
  $item = $ctx->item unless $item;
  return unless $item;

  return
    map { $ctx->field_value_str(field => $_, item => $item)->[3] }
    $item->result_source->primary_columns;
}


1;
