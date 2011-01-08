package Ferdinand::Model;

use Ferdinand::Setup 'class';
use Ferdinand::Utils qw( ehtml ghtml hash_merge parse_structured_key );
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
  my $v = $self->field_value_str(ctx => $ctx, field => $field, item => $item);

  my $meta = $self->field_meta($field);
  my $type = $meta->{data_type} || '';

  my %attrs;
  my $cls = $meta->{cls_field_html};
  $attrs{class} = $cls if $cls;

  if (!defined $v) {
    return $h->div(\%attrs, '') if %attrs && $type eq 'text';
    return $h->span(\%attrs, '') if %attrs;
    return '';
  }

  my $url;
  if ($url = $meta->{link_to}) {
    local $_ = $ctx;
    $url = $url->($item, $v);
  }

  my $opts = $meta->{options};
  if ($opts) {
    for my $o (@$opts) {
      next unless $v eq $o->{id};
      $v = $o->{name};
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

  return $v;
}


method render_field_write(:$ctx, :$field, :$item) {
  my $h    = ghtml();
  my $meta = $self->field_meta($field);
  my $type = $meta->{data_type} || '';
  my $cls  = $meta->{cls_field_html};
  my $def  = $ctx->mode eq 'create' ? 1 : 0;
  my $val  = $self->field_value_str(
    ctx         => $ctx,
    field       => $field,
    item        => $item,
    use_default => $def
  );
  $val = '' if $meta->{empty};

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
    my @inner;
    for my $opt (@$opt) {
      my $id = $opt->{id};
      my %oattrs = (value => $id);
      $oattrs{selected} = 1 if $val && $val eq $id;
      push @inner, $h->option(\%oattrs, $opt->{name});
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

  return $h->input(\%attrs);
}


#############################
# Get field values from Items

method field_value (:$ctx, :$field, :$item) {
  $item = $ctx->item unless $item;
  return unless $item;

  my @path = parse_structured_key($field);

  while ($item && @path) {
    my $name = shift @path;
    confess("FATAL: no support for list fields, ") if ref $name;

    if (blessed($item) && $item->can($name)) { $item = $item->$name() }
    elsif (ref($item) eq 'HASH') { $item = $item->{$name} }
    else                         { $item = undef }
  }

  return $item if defined $item;
  return;
}


method field_value_str (:$ctx, :$field, :$item, :$use_default = 0) {
  my $meta = $self->field_meta($field);
  my $t    = $meta->{data_type} || '';
  my $v    = $self->field_value(ctx => $ctx, field => $field, item => $item);
  if (!$v && $use_default) {
    $v = $meta->{default_value};
    $v = $v->() if ref($v) eq 'CODE';
  }

  my $f = $meta->{formatter};
  if ($f && defined $v) {
    local $_ = $v;
    $v = $f->($self);
  }

  return '' unless defined $v;
  return $v unless ref($v);

  if (blessed($v) eq 'DateTime') {
    return $v->ymd('/') if $t eq 'date';
    return $v->ymd('/') . ' ' . $v->hms;
  }

  return "$v";
}


__PACKAGE__->meta->make_immutable;
1;
