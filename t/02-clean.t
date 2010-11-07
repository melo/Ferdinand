#!perl

use strict;
use warnings;
use Test::More;

my @specs = (['Ferdinand::Action', 'ehtml', 'ghtml']);

for my $spec (@specs) {
  my ($class, @meths) = @$spec;
  eval "require $class";

  ok(!$class->can($_), "Class '$class' has no method '$_'") for @meths;
}

done_testing();
