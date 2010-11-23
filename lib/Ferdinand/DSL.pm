package Ferdinand::DSL;

use Ferdinand::Setup 'library';

our @EXPORT = qw(
  ferdinand_setup ferdinand_map
  actions list view
  action name layout
  title nest
  widget type
  columns
  linked link_to col

  dbic_source dbic_item dbic_set

  cat_ferdinand_setup
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
sub ferdinand_setup (&) { _cb_setup(@_) }
sub ferdinand_map (&) { Ferdinand->setup(meta => _cb_setup(@_)) }


### Action setup
sub actions (&) { _cur_setup()->{actions} = _cb_setup(@_, []) }

sub list (&) {
  my $list = _cur_setup();
  push @$list, {name => 'list', layout => _cb_setup(@_, [])};
}

sub view (&) {
  my $list = _cur_setup();
  push @$list, {name => 'view', layout => _cb_setup(@_, [])};
}

sub action (&) { my $l = _cur_setup(); push @$l, _cb_setup(@_) }


### Action attributes
sub name ($) { _cur_setup()->{name} = $_[0] }
sub layout (&) { _cur_setup()->{layout} = _cb_setup(@_, []) }


### Widget shortcuts
sub title ($) {
  my $list = _cur_setup();
  push @$list, {title => $_[0], type => 'Title'};
}

sub nest (&) {
  my $list = _cur_setup();
  push @$list, {type => 'Layout', clone => 1, layout => _cb_setup(@_, [])};
}


### DBIC widgets shortcuts
sub dbic_source (&) {
  my $list = _cur_setup();
  push @$list, {type => 'DBIC::Source', source => $_[0]};
}

sub dbic_item (&) {
  my $list = _cur_setup();
  push @$list, {type => 'DBIC::Item', item => $_[0]};
}

sub dbic_set (&) {
  my $list = _cur_setup();
  push @$list, {type => 'DBIC::Set', set => $_[0]};
}


### Widget setup and main attributes
sub widget (&) { my $l = _cur_setup(); push @$l, _cb_setup(@_) }
sub type ($) { _cur_setup()->{type} = $_[0] }


### Column definition
sub columns (&) { _cur_setup()->{columns} = _cb_setup(@_, []) }
sub linked ($$)  { my $l = _cur_setup(); push @$l, $_[0], {linked  => $_[1]} }
sub link_to ($$) { my $l = _cur_setup(); push @$l, $_[0], {link_to => $_[1]} }
sub col ($)      { my $l = _cur_setup(); push @$l, $_[0] }


### Extras
sub cat_ferdinand_setup (&) { caller()->ferdinand(_cb_setup(@_)) }


1;
