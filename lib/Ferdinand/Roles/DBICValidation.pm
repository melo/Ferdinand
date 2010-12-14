package Ferdinand::Roles::DBICValidation;

use Ferdinand::Setup 'role';
use Method::Signatures;
use Ferdinand::Utils qw(hash_select hash_grep);
use DateTime::Format::MySQL;

requires 'dbic_action';

has 'valid' => (
  isa     => 'CodeRef',
  is      => 'ro',
  default => sub {
    sub { }
  },
);


after setup_attrs => sub {
  my ($class, $attrs, $meta) = @_;

  $attrs->{valid} = delete $meta->{valid} if exists $meta->{valid};
};

after render_self => sub {
  my ($self, $ctx) = @_;

  my $fields = hash_grep { !/^btn_/ } $ctx->params;
  if (my $valid = $self->valid) {
    local $_ = $ctx;
    $fields = $valid->($self);
  }
  return unless $fields && ref($fields) eq 'HASH';

  $self->_validate($ctx, $fields);
  return if $ctx->has_errors;

  $self->dbic_action($ctx, $fields);
};

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

method _validate($ctx, $fields) {
  my $model = $ctx->model;
    my $src = $model->source;

    for my $col ($src->columns) {
    next unless exists $fields->{$col};

    my $i    = $src->column_info($col);
    my $t    = $i->{data_type};
    my $mt   = $meta_types{$t};
    my $req  = !$i->{is_nullable};
    my $meta = $model->column_meta_fixup($col);

    my $v = $ctx->field_value_str($col, $meta, $fields);
    $v =~ s/^\s+|\s+$//g;
    my $lv = length($v);

    if ($req && $mt eq 'text' && $lv == 0) {
      $ctx->add_error($col => 'Campo obrigatório');
    }

    if ($lv > 0 && $t eq 'datetime') {
      $v =~ s{/}{-}g;
      eval { $v = DateTime::Format::MySQL->parse_datetime($v) };
      $ctx->add_error($col => "Data/Hora inválida ($@)") if $@;
    }

    if ($lv > 0 && $t eq 'date') {
      $v =~ s{/}{-}g;
      eval { $v = DateTime::Format::MySQL->parse_date($v) };
      $ctx->add_error($col => "Data inválida ($@)") if $@;
    }

    $self->_check_db_restrictions($ctx, $fields);

    $fields->{$col} = $v;
  }
  }

  method _check_db_restrictions($ctx, $fields) {
  my $src  = $ctx->model->source;
    my %un = $src->unique_constraints;

    for my $name (keys %un) {
    my $flds = $un{$name};
    my $sel = hash_select($fields, @$flds);
    next unless scalar(@$flds) == scalar(keys %$sel);

    next unless $src->resultset->count($sel);
    $ctx->add_error($_, "Elemento duplicado ($name)") for @$flds;
    last;
  }
  }

  1;
