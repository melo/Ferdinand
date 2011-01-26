#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::Utils qw(
  read_data_files get_data_files
  render_template
  ghtml ehtml
  hash_merge hash_select hash_grep hash_cleanup hash_decode
  load_class load_widget
  expand_structure parse_structured_key select_structure
  walk_structure
);
use Sample;

## Read __DATA__ files
my $files = Sample->load_them;
ok($files, 'Got some files');
cmp_deeply(
  [keys %$files],
  bag('file1.txt', 'file2.html', 'list.pltj'),
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


subtest 'Template processing', sub {
  require_tenjin();

  my $data = {
    title => 'Me',
    items => [
      {rank => 1, name => 'First'},
      {rank => 2, name => 'Second'},
      {rank => 3, name => 'Third'},
    ]
  };

  my $expected = <<EOF;
title Me
  1. First
  2. Second
  3. Third

EOF

  my $output;
  is(
    exception { $output = Sample->render('list.pltj', $data) },
    undef, 'no exception for render_template()',
  );

  is($output, $expected, 'Expected output from template rendering');
  is(render_template('list.pltj', $data, 'Sample'),
    $expected, '... also if called with specific Class');

  like(
    exception { render_template('no_such_template', {}, 'Sample') },
    qr/Template 'no_such_template' not found in class 'Sample',/,
    'render_template() died properly if template not found'
  );
};


subtest 'Generate/Escape HTML', sub {
  my $html = ghtml->a({href => 'url', class => undef}, 'test &');
  is($html, '<a href="url">test &amp;</a>', 'HTML generated properly');

  is(
    ehtml('cool > cold & everything else <'),
    'cool &gt; cold &amp; everything else &lt;',
    'HTML escaped properly'
  );

  is(ghtml()->div(\'<<>>'), '<div><<>></div>', 'Unescaped HTML');
};


subtest 'Merge hashref with a hash' => sub {
  my $h = {a => 1, b => 2};

  my $y = hash_merge($h, a => 2, b => undef, c => 3);
  cmp_deeply($h, {a => 2, c => 3}, 'hash_merge works');
  is($y, $h, '... and it returns the input hash');
};


subtest 'Hash select' => sub {
  my $h = {a => 1, b => 2, c => 3};
  cmp_deeply(hash_select($h, qw(a b d)), {a => 1, b => 2});
};


subtest 'Hash grep' => sub {
  my %in = (btn_xpto => 1, text => 'something', radio => 'selected');

  my $hg = hash_grep { !/^btn_/ } \%in;
  cmp_deeply(
    $hg,
    {text => 'something', radio => 'selected'},
    'hash_grep in scalar context ok'
  );

  my %hg = hash_grep {/^t/} \%in;
  cmp_deeply(\%hg, {text => 'something'}, 'hash_grep in list context ok');
};


subtest 'hash_cleanup' => sub {
  cmp_deeply(hash_cleanup({a => 1, b => undef}, qw( b c )), {a => 1});
  cmp_deeply(
    hash_cleanup({a => [], b => {a => undef}}, qw( b a )),
    {a => []},
  );
  cmp_deeply(
    hash_cleanup({a => [], b => {a => 1, b => undef}}, qw( b a )),
    {a => [], b => {a => 1}},
  );
  cmp_deeply(
    hash_cleanup({a => [], b => {a => 1, b => undef}, c => undef}),
    {a => [], b => {a => 1}},
  );
};


subtest 'hash_decode' => sub {
  require Encode;
  my $utf8_str = Encode::decode('iso-8859-1', 'áéíóú');
  my $utf8_octets = Encode::encode('utf8', $utf8_str);

  my $r = hash_decode({u => $utf8_octets});
  is($r->{u}, $utf8_str, 'string decoded properly');
};


subtest 'load_* utils' => sub {
  my $c;

  is(exception { $c = load_class('Ferdinand::Map') },
    undef, 'Load class Ferdinand::Map ok');
  is($c, 'Ferdinand::Map', '... with the expected return value');

  is(exception { $c = load_widget('Title') }, undef, 'Load widget Title ok');
  is($c, 'Ferdinand::Widgets::Title', '... with the expected class returned');

  is(exception { $c = load_widget('+TestRenderMode') },
    undef, 'Load widget TestRenderMode ok');
  is($c, 'TestRenderMode', '... with the expected class returned');

  like(
    exception { load_class("Ferdinand::WeDontHaveThY::$$") },
    qr{Can't locate Ferdinand/WeDontHaveThY/$$.pm},
    'Failed to load class, died ok'
  );
};


subtest 'expand_structure' => sub {
  my @test_cases = (
    { in  => {key => 'value'},
      out => {key => 'value'},
    },
    { in  => {'key1.key2' => 'value'},
      out => {key1        => {key2 => 'value'}},
    },
    { in => {'key1.key2' => 'value', 'key1.key3' => 'value'},
      out => {key1 => {key2 => 'value', key3 => 'value'}},
    },
    { in  => {'key1.key2[0]' => 'value'},
      out => {key1           => {key2 => ['value']}},
    },
    { in  => {'key1.key2[1]' => 'value'},
      out => {key1           => {key2 => [undef, 'value']}},
    },
    { in  => {'key1.key2[1].key3' => 'value'},
      out => {key1                => {key2 => [undef, {key3 => 'value'}]}},
    },
    { in => {
        'key1.key2[0].key3' => 'v1',
        'key1.key2[1].key4' => 'v2',
        'key1.key2[1].key5' => 'v3',
      },
      out =>
        {key1 => {key2 => [{key3 => 'v1'}, {key4 => 'v2', key5 => 'v3'}]}},
    },
  );

  for my $t (@test_cases) {
    my $desc = join(', ', keys %{$t->{in}});
    cmp_deeply(expand_structure($t->{in}), $t->{out}, "Expanded '$desc' ok");
  }
};


subtest 'parse_structured_key' => sub {
  my @test_cases = (
    { in  => 'key',
      out => [qw(key)],
    },
    { in  => 'key1.key2',
      out => [qw( key1 key2 )],
    },
    { in  => 'key1.key2[0]',
      out => ['key1', 'key2', \(0)],
    },
    { in  => 'key1.key2[1]',
      out => ['key1', 'key2', \(1)],
    },
    { in  => 'key1.key2[1].key3',
      out => ['key1', 'key2', \(1), 'key3'],
    },
  );

  for my $t (@test_cases) {
    cmp_deeply([parse_structured_key($t->{in})],
      $t->{out}, "Parsed '$t->{in}' ok");
  }
};


subtest 'select_structure' => sub {
  my $source = {
    a => {b => 1},
    c => {d => {e => 2}},
    f => 4,
  };

  my @test_cases = (
    { in  => [qw( a.b c.g g f.h )],
      out => {a => {b => 1}},
    },
    { in  => [qw( a.g c.d.e g.h f )],
      out => {c => {d => {e => 2}}, f => 4},
    },
  );

  for my $t (@test_cases) {
    my $desc = join(', ', @{$t->{in}});
    cmp_deeply(select_structure($source, @{$t->{in}}),
      $t->{out}, "Selected '$desc' ok");
  }
};


subtest 'walk_structure' => sub {
  my $source = {
    a => {b => 1},
    c => {d => {e => 2}},
    f => 4,
  };

  my @test_cases = (
    { in  => 'a.b',
      out => [{b => 1}, 'b', 1],
    },
    { in  => 'a.c',
      out => [{b => 1}, 'c', undef],
    },
    { in  => 'c.d',
      out => [{d => {e => 2}}, 'd', {e => 2}],
    },
    { in  => 'c.d.e',
      out => [{e => 2}, 'e', 2],
    },
    { in  => 'f',
      out => [$source, 'f', 4],
    },
    { in  => 'a.c.d',
      out => [undef, 'd', undef],
    },
  );

  for my $t (@test_cases) {
    my $in = $t->{in};
    cmp_deeply(walk_structure($source, $in), $t->{out},
      "walked for '$in' ok");
  }
};


done_testing();
