#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Fatal;
use Test::Deep;
use Ferdinand::Utils 'read_data_files', 'get_data_files';
use Sample;

## Read __DATA__ files
my $files = Sample->load_them;
ok($files, 'Got some files');
cmp_deeply(
  [keys %$files],
  bag('file1.txt', 'file2.html'),
  '... looks like the expected filenames'
);

like(
  $files->{'file1.txt'},
  qr/There are many others like it/,
  'file1.txt has the expected content'
);
like(
  $files->{'file2.html'},
  qr/We love HTML5!/,
  'file2.html has the expected content'
);
unlike(
  $files->{'file2.html'},
  qr/This is not part of that/,
  'file2.html does not have the extra content'
);

my $sample_files = read_data_files('Sample');
cmp_deeply($files, $sample_files, 'Calling with a direct Class also works');


## Make sure we have a cache of our templates
{
  no strict 'refs';
  is(${'Sample::Ferdinand_Utils_get_data_files'},
    undef, 'No cache active before call get_data_files()');
}

my $cached_files1 = get_data_files('Sample');
ok($cached_files1, 'Got some cached files');
is(ref($cached_files1), 'HASH', '... of the expected type');
{
  no strict 'refs';
  is(ref(${'Sample::Ferdinand_Utils_get_data_files'}),
    'HASH', 'Package cache is set');
}

cmp_deeply($cached_files1, $files,
  'Cached files are the same as the ones we read');

my $cached_files2 = get_data_files('Sample');
is("$cached_files1", "$cached_files2",
  'Second call to get_data_files() returns same structure');

done_testing();
