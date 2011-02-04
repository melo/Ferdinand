package Ferdinand::Model;

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw(
  ehtml ghtml
  hash_merge
  empty
  parse_structured_key walk_structure
);
use Method::Signatures;


################
# Field Metadata

has '_field_meta' => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => undef,
  default  => sub { {} },
);

method set_field_meta ($name, $meta) {
  my $fm = $self->_field_meta;
  if (my $m = $fm->{$name}) {
    my $fn = $m->{_file};
    my $ln = $m->{_line};
    confess "Field '$name' already exists (defined at $fn, line $ln), ";
  }

  # FIXME: we need to skip Ferdinand::* classes
  ($meta->{_file}, $meta->{_line}) = (caller())[1, 2];
  $fm->{$name} = $meta;
}

method field_meta ($name) {
  my $fm = $self->_field_meta;
  return $fm->{$name} if exists $fm->{$name};
  return {};
}


##################
# Render of fields

method render_field (:$ctx, :$field, :$item) {
  my $m = $ctx->mode;
  return $self->render_field_read(@_)  if $m eq 'view'   || $m eq 'list';
  return $self->render_field_write(@_) if $m eq 'create' || $m eq 'create_do';
  return $self->render_field_write(@_) if $m eq 'edit'   || $m eq 'edit_do';
}

method render_field_read (:$ctx, :$field, :$item) {
  my $h = ghtml();

  $item = $ctx->item unless $item;

  my $meta = $self->field_meta($field);
  my $f = $self->_get_fixed_value($ctx, $item, $field, $meta);
  $f = $self->field_value_str(@_, item => $item)
    unless $f;
  my $v = $f->[3];

  my $type = $meta->{data_type} || '';

  my %attrs;
  my $cls = $meta->{cls_field_html};
  $attrs{class} = $cls if $cls;

  if (length($v) == 0) {
    return $h->div(\%attrs, '') if %attrs && $type eq 'text';
    return $h->span(\%attrs, '') if %attrs;
    return '';
  }

  my $url;
  if ($url = $meta->{link_to}) {
    local $_ = $ctx;
    $url = $url->($f->[0], $v);
  }

  my $opts = $meta->{options};
  if ($opts) {
    for my $o (@$opts) {
      next unless $v eq $o->{id};
      $v = $o->{text};
      last;
    }
  }

  my $fmt = $meta->{format} || '';
  if ($fmt eq 'html') {
    my $x = $v;
    $v = \$x;
  }

  if ($url) {
    $attrs{href} = $url;
    $v = $h->a(\%attrs, $v);
  }
  elsif (ref($v)) {
    $attrs{class} = $attrs{class} ? "$attrs{class} html_fmt" : 'html_fmt';
    $v = $h->div(\%attrs, $v);
  }
  elsif ($type eq 'text') {
    $v = $h->div(\%attrs, $v);
  }
  elsif (%attrs) {
    $v = $h->span(\%attrs, $v);
  }
  else {
    $v = ehtml($v);
  }

  $v = $v->stringify if ref($v);
  return $v;
}


method render_field_write(:$ctx, :$field, :$item) {
  my $h = ghtml();

  my $meta = $self->field_meta($field);
  my $type = $meta->{data_type} || '';
  my $cls  = $meta->{cls_field_html};
  my $def  = $ctx->mode eq 'create' ? 1 : 0;

  my $f = $self->_get_fixed_value($ctx, $item, $field, $meta);
  $f = $self->field_value_str(
    ctx         => $ctx,
    field       => $field,
    item        => $item,
    use_default => $def
  ) unless $f;
  my $val = $f->[3];
  $val = '' if $meta->{empty};

  my $prefix = $ctx->prefix;
  $field = "$prefix.$field" if $prefix;
  my %attrs = (
    id   => $field,
    name => $field,
  );
  $attrs{class} = $cls if $cls;

  if ($meta->{format} && $meta->{format} eq 'html') {
    my $t = $val;
    $val = \$t;
  }

  if (my $opt = $meta->{options}) {
    if (ref($opt) eq 'CODE') {
      local $_ = $ctx;
      $opt = $opt->($item);
    }

    my @inner;
    push @inner, $h->option($meta->{empty_option} || '')
      if exists $meta->{empty_option} || $meta->{is_nullable};

    for my $opt (@$opt) {
      my $id = $opt->{id};
      my %oattrs = (value => $id);
      $oattrs{selected} = 1 if $val && $val eq $id;
      push @inner, $h->option(\%oattrs, $opt->{text});
    }
    return $h->select(\%attrs, @inner);
  }
  elsif ($type eq 'text') {
    $attrs{cols} = 100;
    $attrs{rows} = 6;
    if ($meta->{format} && $meta->{format} eq 'html') {
      $attrs{class} = $attrs{class} ? "$attrs{class} html_fmt" : 'html_fmt';
      $attrs{rows} += 12;
    }

    return $h->textarea(\%attrs, $val);
  }
  elsif ($type eq 'char' || $type eq 'varchar') {
    if (my $size = $meta->{size}) {
      $attrs{maxlength} = $size;
      $attrs{size}      = $size;
    }
    if (my $width = $meta->{width}) {
      $attrs{size} = $width;
    }
  }
  elsif ($type eq 'date') {
    $attrs{type} = 'date';
  }

  $attrs{required} = 1      unless $meta->{is_nullable};
  $attrs{type}     = 'text' unless $attrs{type};
  $attrs{value}    = $val;

  my $html = '';
  if ($meta->{fixed}) {    ## fixed meta
    $attrs{type} = 'hidden';
    $html = $self->render_field_read(@_, item => $item);
  }

  return $h->input(\%attrs) . $html;
}

method _get_fixed_value ($ctx, $item, $field, $meta) {
  return unless exists $meta->{value};

  my $v = $meta->{value};
  if (ref($v) eq 'CODE') {
    local $_ = $ctx;
    $v = $v->($item);
  }
  $v = '' if empty($v);

  return [$item, $field, $v, $v, 1];
}


#############################
# Get field values from Items

method field_value (:$ctx, :$field, :$item) {
  $item = $ctx->item unless $item;

  my $p = $ctx->prefix;
  $field = "$p.$field" if $p && !blessed($item);

  return walk_structure($item, $field)
}


method field_value_str (:$ctx, :$field, :$item, :$use_default = 0) {
  my $meta = $self->field_meta($field);
  my $t    = $meta->{data_type} || '';
  my $fv   = $self->field_value(ctx => $ctx, field => $field, item => $item);
  
  my $v    = $fv->[2];
  if (!$v && $use_default) {
    $v = $meta->{default_value};
    $v = $v->() if ref($v) eq 'CODE';
  }

  my $f = $meta->{formatter};
  if ($f && defined $v) {
    local $_ = $v;
    $v = $f->($self);
  }

  return [@$fv, ''] unless defined $v;
  return [@$fv, $v] unless ref($v);

  my $class = blessed($v);
  if ($class eq 'DateTime') {
    return [@$fv, $v->ymd('/')] if $t eq 'date';
    return [@$fv, $v->ymd('/') . ' ' . $v->hms];
  }
  elsif ($class eq 'Data::Currency') {
    return [@$fv, $v->value];
  }

  return [@$fv, "$v"];
}


method fetch ($id, $source) {
  confess "Subclass $self needs to implement fetch(), ";
}


method column_meta_fixup () {
  confess "Subclass $self needs to implement column_meta_fixup(), ";
}


method id_for_item ($item) {
  confess "Subclass $self needs to implement id_for_item(), ";
}


__PACKAGE__->meta->make_immutable;
1;
