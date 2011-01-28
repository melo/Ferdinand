#!perl

use strict;
use warnings;
use Test::More;
use Test::Compile;

all_pm_files_ok(grep { !m{Ferdinand/DSL.pm$} } all_pm_files());

done_testing();
