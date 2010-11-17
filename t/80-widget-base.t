#!perl

use strict;
use warnings;
use Test::More;
use Ferdinand::Widget;

my $w = Ferdinand::Widget->new;
isa_ok($w, 'Ferdinand::Widget', 'Proper class name for widget object');

for my $m (qw( render render_self render_end setup setup_attrs )) {
  ok($w->can($m), "... widget has method '$m'");
}


done_testing();
