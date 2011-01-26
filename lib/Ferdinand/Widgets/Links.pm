package Ferdinand::Widgets::Links;

use Ferdinand::Setup 'class';
use Method::Signatures;
use Ferdinand::Utils qw(render_template);

extends 'Ferdinand::Widget';

has 'links' => (
  isa => 'ArrayRef[HashRef]',
  is  => 'ro',
);

after setup_fields => method ($fields) { push @$fields, 'links' };


method render_self ($ctx) {
  my $links = $self->links;
  return unless @$links;

  my @sl;
  for my $l (@$links) {
    my $u = $l->{url};
    if (ref($u) eq 'CODE') {
      local $_ = $ctx;
      $u = $u->($ctx->item, $self);
    }

    push @sl, {url => $u, title => $l->{title}};
  }

  $ctx->buffer(render_template('links.pltj', {ctx => $ctx, links => \@sl}));
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ links.pltj
<?pl #@ARGS ctx, links ?>

<?pl if (@$links) { ?>
<div class="oplinks">
  <ul>
<?pl   for my $l (@$links) { ?>
    <li><a href="[= $l->{url} =]">[= $l->{title} =]</a></li>
<?pl   } ?>
  </ul>
</div>
<?pl } ?>
