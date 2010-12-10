#!perl

use strict;
use warnings;
use Test::More;
use Ferdinand::Widget;

my $w = Ferdinand::Widget->new(id => 'id_1');
isa_ok($w, 'Ferdinand::Widget', 'Proper class name for widget object');

is($w->id, 'id_1', 'Proper id');

for my $m (qw( render render_self render_end setup setup_attrs id )) {
  ok($w->can($m), "... widget has method '$m'");
}


done_testing();
