package Ferdinand::DSL;

use Ferdinand::Setup 'library';

our @EXPORT = qw(
  ferdinand_setup cat_ferdinand_setup
  dbic_source
  list view
  title columns
  linked link_to col
);


### Our setup stack
{
  our @stack;

  sub _cur_setup { $stack[-1] }

  sub _cb_setup {
    my ($cb, $def) = @_;
    $def ||= {};

    push @stack, $def;
    $cb->(@_);
    pop @stack;

    return $def;
  }
}


### Ferdinand global setup
sub cat_ferdinand_setup (&) { caller()->ferdinand(_cb_setup(@_)) }
sub ferdinand_setup (&)     { _cb_setup(@_) }

### Picking an implementation
sub dbic_source (&) { _cur_setup()->{source} = $_[0]->() }

### Action setup
sub list (&) { _cur_setup()->{list} = _cb_setup(@_) }
sub view (&) { _cur_setup()->{view} = _cb_setup(@_) }

### Action attributes
sub title ($) { _cur_setup()->{title} = $_[0] }
sub columns (&) { _cur_setup()->{columns} = _cb_setup(@_, []) }

### Column definition
sub linked ($$)  { my $l = _cur_setup(); push @$l, $_[0], {linked  => $_[1]} }
sub link_to ($$) { my $l = _cur_setup(); push @$l, $_[0], {link_to => $_[1]} }
sub col ($)      { my $l = _cur_setup(); push @$l, $_[0] }

1;
