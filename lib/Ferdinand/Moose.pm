package Ferdinand::Moose;

# ABSTRACT: Import Moose and a whole lot more

use strict;
use warnings;
use feature ();
use utf8;
require Moose;

sub import {
  feature->import(':5.12');
  utf8->import();

  goto \&Moose::import;
}

1;
