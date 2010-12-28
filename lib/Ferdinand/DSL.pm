package Ferdinand::DSL;

use Ferdinand::Setup 'library';

our @EXPORT = qw(
  ferdinand_setup ferdinand_map
  actions list view create edit
  action name layout
  title header nest execute
  widget type attr
  columns cols
  linked link_to col
  links url

  dbic_source dbic_item dbic_set dbic_create dbic_update
  form button label on_click

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

  sub _add_setup {
    my ($name, $info) = @_;
    my $ctx = $stack[-1];

    if (ref($ctx) eq 'ARRAY') {
      push @$ctx, $name;
      push @$ctx, $info if defined $info;
    }
    else {
      $ctx->{$name} = $info;
    }
  }
}


### Ferdinand global setup
sub ferdinand_setup (&) { _cb_setup(@_) }
sub ferdinand_map (&) { Ferdinand->setup_map(_cb_setup(@_)) }


### Action setup
sub actions (&) { _add_setup actions => _cb_setup(@_, []) }
sub action (&) { _add_setup _cb_setup(@_) }

sub list (&)   { _add_setup {name => 'list',   layout => _cb_setup(@_, [])} }
sub view (&)   { _add_setup {name => 'view',   layout => _cb_setup(@_, [])} }
sub edit (&)   { _add_setup {name => 'edit',   layout => _cb_setup(@_, [])} }
sub create (&) { _add_setup {name => 'create', layout => _cb_setup(@_, [])} }


### Action attributes
sub attr ($$)  { _add_setup @_ }
sub name ($)   { _add_setup name => $_[0] }
sub layout (&) { _add_setup layout => _cb_setup(@_, []) }


### Widget shortcuts
sub title ($)   { _add_setup {title  => $_[0], type => 'Title'} }
sub header ($)  { _add_setup {header => $_[0], type => 'Header'} }
sub execute (&) { _add_setup {cb     => $_[0], type => 'CB'} }


### DBIC widgets shortcuts
sub dbic_source (&) { _add_setup {type => 'DBIC::Source', source => $_[0]} }
sub dbic_item (&)   { _add_setup {type => 'DBIC::Item',   item   => $_[0]} }
sub dbic_set (&)    { _add_setup {type => 'DBIC::Set',    set    => $_[0]} }
sub dbic_create (&) { _add_setup {type => 'DBIC::Create', valid  => $_[0]} }
sub dbic_update (&) { _add_setup {type => 'DBIC::Update', valid  => $_[0]} }


### Widget setup and main attributes
sub widget (&) { _add_setup _cb_setup(@_) }
sub type ($) { _add_setup type => $_[0] }


### Link widget
sub links (&) { _add_setup {type => 'Links', links => _cb_setup(@_, [])} }
sub url { _add_setup {title => $_[0], url => $_[1]} }


### Column definition
sub cols { _add_setup columns => [@_] }

sub columns (&) { _add_setup columns => _cb_setup(@_, []) }

sub linked ($$)  { _add_setup $_[0] => {linked  => $_[1]} }
sub link_to ($$) { _add_setup $_[0] => {link_to => $_[1]} }
sub col ($)      { _add_setup $_[0] }


### Forms
sub form (&) { _add_setup {type => 'Form', layout => _cb_setup(@_, [])} }

sub button (&) { _add_setup _cb_setup(@_, {type => 'Form::Button'}) }
sub label ($) { _add_setup label => $_[0] }

sub on_click (&) {
  _add_setup layout => _cb_setup(@_, []);
  _add_setup on_demand => 1;
}


### Extras
sub cat_ferdinand_setup (&) { caller()->ferdinand(_cb_setup(@_)) }


1;
