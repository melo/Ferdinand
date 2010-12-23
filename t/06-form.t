#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::MockObject;
use Ferdinand::Form;
use Ferdinand::Context;
use DateTime;

sub _ctx {
  my @extra_args = @_;
  my $ctx;

  is(
    exception {
      $ctx = Ferdinand::Context->new(
        map    => bless({}, 'Ferdinand::Map'),
        action => bless({}, 'Ferdinand::Action'),
        @extra_args,
      );
    },
    undef,
    'Context created, no exceptions'
  );

  return $ctx;
}


subtest 'render_field output' => sub {
  my $i = Test::MockObject->new;
  $i->set_always(v  => '<abcd & efgh>');
  $i->set_always(e  => '!!');
  $i->set_always(id => 1);

  my $c1 = _ctx(item => $i);

  my %args = (
    field => 'v',
    meta  => {},
  );

  is($c1->render_field(%args), '&lt;abcd &amp; efgh&gt;', 'Single row value');

  $args{meta}{formatter} = sub { return uc($_) };
  is(
    $c1->render_field(%args),
    '&lt;ABCD &amp; EFGH&gt;',
    'Single row value, with formatter'
  );

  $args{meta}{cls_field_html} = 'x y z';
  is(
    $c1->render_field(%args),
    '<span class="x y z">&lt;ABCD &amp; EFGH&gt;</span>',
    'Single row value, with class'
  );

  $args{meta}{link_to} = sub { $_->e };
  like_all(
    'link_to value + class',
    $c1->render_field(%args),
    qr{^<a }, qr{ class="x y z"},
    qr{ href="!!"}, qr{>&lt;ABCD &amp; EFGH&gt;</a>},
  );

  delete $args{meta}{cls_field_html};
  $args{meta}{link_to} = sub { $_->e };
  is(
    $c1->render_field(%args),
    '<a href="!!">&lt;ABCD &amp; EFGH&gt;</a>',
    'link_to value'
  );

  $args{meta}{linked} = ['view', 'me'];
  is($c1->render_field(%args), '&lt;ABCD &amp; EFGH&gt;', 'linked value');

  my $g = $c1->overlay(uri_helper => sub { return join('/', @{$_[1]}) });
  is(
    $c1->render_field(%args),
    '<a href="view/me">&lt;ABCD &amp; EFGH&gt;</a>',
    'link_to value, with formatter'
  );

  $i = Test::MockObject->new;
  $i->set_always(x => '<ABCD & EFGH>');
  is(
    $c1->render_field(field => 'x', meta => {}, item => $i),
    '&lt;ABCD &amp; EFGH&gt;',
    'Override item on render_field ok'
  );

  is(
    $c1->render_field(field => 'x', meta => {format => 'html'}, item => $i),
    '<div class="html_fmt"><ABCD & EFGH></div>',
    'HTML format in fields renders ok'
  );

  ## Check influence of modes with render_field
  my $mock_42 = Test::MockObject->new;
  $mock_42->set_always(x => '42');

  for my $item ({x => '42'}, $mock_42) {
    for my $m (qw( view list )) {
      my $g = $c1->overlay(mode => $m);
      is($c1->render_field(field => 'x', item => $item),
        '42', "Proper render_field() output for mode '$m' (item $item)");
    }
    for my $m (qw( create create_do edit edit_do )) {
      my $g = $c1->overlay(mode => $m);
      like_all(
        "Proper render_field() output for mode '$m' (item $item)",
        $c1->render_field(field => 'x', item => $item),
        qr{<input },
        qr{type="text"},
        qr{name="x"},
        qr{id="x"},
        qr{value="42"},
      );
    }
  }
};


subtest 'render_field_read', sub {
  my $c1 = _ctx();

  is($c1->render_field_read(field => 'xpto'), '', 'xpto bare input');

  is($c1->render_field_read(field => 'xpto', item => {xpto => 'aa'}),
    'aa', 'xpto with previous value');

  is(
    $c1->render_field_read(
      field => 'xpto',
      meta  => {cls_field_html => 'x y z'},
      item  => {xpto => 'aa'}
    ),
    '<span class="x y z">aa</span>',
    'xpto with previous value + class'
  );

  is($c1->render_field_read(field => 'xpto', meta => {is_nullable => 1}),
    '', 'xpto with meta for optional file');

  is(
    $c1->render_field_read(
      field => 'xpto',
      meta  => {data_type => 'date'},
      item  => {xpto => DateTime->new(year => 2001, month => 9, day => 10)},
    ),
    '2001/09/10',
    'xpto with meta type date',
  );

  is(
    $c1->render_field_read(
      field => 'xpto',
      meta  => {data_type => 'char', size => 10},
      item => {xpto => 'yuppi'}
    ),
    'yuppi',
    'xpto with meta type char with size'
  );

  is(
    $c1->render_field_read(field => 'xpto', meta => {data_type => 'varchar'}),
    '',
    'xpto with meta type varchar'
  );

  is($c1->render_field_read(field => 'xpto', meta => {data_type => 'text'}),
    '<div></div>', 'xpto text field');

  is(
    $c1->render_field_read(
      field => 'xpto',
      meta  => {data_type => 'text', cls_field_html => 'x y z'}
    ),
    '<div class="x y z"></div>',
    'xpto text field + class'
  );

  is(
    $c1->render_field_read(
      field => 'xpto',
      meta =>
        {data_type => 'text', cls_field_html => 'x y z', format => 'html'},
      item => {xpto => '<br>'}
    ),
    '<div class="x y z html_fmt"><br></div>',
    'xpto text field, HTML formatted + class'
  );

  is(
    $c1->render_field_read(
      field => 'xpto',
      meta  => {data_type => 'text'},
      item  => {xpto => 'yyy'},
    ),
    '<div>yyy</div>',
    'xpto text field + value'
  );

  is(
    $c1->render_field_read(
      field => 'xpto',
      meta =>
        {options => [{id => 'a', name => 'A'}, {id => 'b', name => 'B'}]}
    ),
    '',
    'xpto field with options, no value'
  );

  is(
    $c1->render_field_read(
      field => 'xpto',
      meta  => {
        options => [{id => 'a', name => 'AA'}, {id => 'b', name => 'BB'}],
        cls_field_html => 'x y z'
      }
    ),
    '<span class="x y z"></span>',
    'xpto field with options + class'
  );

  is(
    $c1->render_field_read(
      field => 'xpto',
      meta =>
        {options => [{id => 'a', name => 'A'}, {id => 'b', name => 'B'}]},
      item => {xpto => 'b'},
    ),
    'B',
    'xpto field with options + value'
  );
};


subtest 'render_field_write', sub {
  my $c1 = _ctx();

  like_all(
    'xpto bare input',
    $c1->render_field_write(field => 'xpto'),
    qr{<input }, qr{type="text"}, qr{name="xpto"}, qr{id="xpto"},
    qr{required="1"},
  );

  like_all(
    'xpto with previous value',
    $c1->render_field_write(
      field => 'xpto',
      item  => {xpto => 'aa'}
    ),
    qr{<input },
    qr{type="text"},
    qr{name="xpto"},
    qr{id="xpto"},
    qr{required="1"},
    qr{value="aa"},
  );

  like_all(
    'xpto with previous value + class',
    $c1->render_field_write(
      field => 'xpto',
      meta  => {cls_field_html => 'x y z'},
      item  => {xpto => 'aa'}
    ),
    qr{<input },
    qr{type="text"},
    qr{name="xpto"},
    qr{id="xpto"},
    qr{required="1"},
    qr{value="aa"},
    qr{class="x y z"},
  );

  like_all(
    'xpto with meta for optional file',
    $c1->render_field_write(
      field => 'xpto',
      meta  => {is_nullable => 1}
    ),
    qr{<input },
    qr{type="text"},
    qr{name="xpto"},
    qr{id="xpto"},
  );

  like_all(
    'xpto with meta type date',
    $c1->render_field_write(
      field => 'xpto',
      meta  => {data_type => 'date'}
    ),
    qr{<input },
    qr{type="date"},
    qr{name="xpto"},
    qr{id="xpto"},
  );

  like_all(
    'xpto with meta type char with size',
    $c1->render_field_write(
      field => 'xpto',
      meta  => {data_type => 'char', size => 10}
    ),
    qr{<input },
    qr{type="text"},
    qr{name="xpto"},
    qr{id="xpto"},
    qr{maxlength="10"},
    qr{size="10"},
  );

  like_all(
    'xpto with meta type varchar',
    $c1->render_field_write(
      field => 'xpto',
      meta  => {data_type => 'varchar'}
    ),
    qr{<input },
    qr{type="text"},
    qr{name="xpto"},
    qr{id="xpto"},
  );

  like_all(
    'xpto textarea',
    $c1->render_field_write(
      field => 'xpto',
      meta  => {data_type => 'text'}
    ),
    qr{<textarea },
    qr{></textarea>},
    qr{cols="100"},
    qr{rows="6"},
    qr{name="xpto"},
    qr{id="xpto"},
  );

  like_all(
    'xpto textarea + class',
    $c1->render_field_write(
      field => 'xpto',
      meta  => {data_type => 'text', cls_field_html => 'x y z'}
    ),
    qr{<textarea },
    qr{></textarea>},
    qr{cols="100"},
    qr{rows="6"},
    qr{name="xpto"},
    qr{id="xpto"},
    qr{class="x y z"},
  );

  like_all(
    'xpto textarea + class',
    $c1->render_field_write(
      field => 'xpto',
      meta =>
        {data_type => 'text', cls_field_html => 'x y z', format => 'html'},
      item => {xpto => '<br>'},
    ),
    qr{<textarea },
    qr{><br></textarea>},
    qr{cols="100"},
    qr{rows="18"},
    qr{name="xpto"},
    qr{id="xpto"},
    qr{class="x y z html_fmt"},
  );

  like_all(
    'xpto textarea',
    $c1->render_field_write(
      field => 'xpto',
      meta  => {data_type => 'text'},
      item  => {xpto => 'yyy'},
    ),
    qr{<textarea },
    qr{>yyy</textarea>},
    qr{cols="100"},
    qr{rows="6"},
    qr{name="xpto"},
    qr{id="xpto"},
  );

  like_all(
    'xpto select',
    $c1->render_field_write(
      field => 'xpto',
      meta =>
        {options => [{id => 'a', name => 'A'}, {id => 'b', name => 'B'}]}
    ),
    qr{<select },
    qr{name="xpto"},
    qr{id="xpto"},
    qr{<option value="a">A</option>},
    qr{<option value="b">B</option>},
  );

  like_all(
    'xpto select + class',
    $c1->render_field_write(
      field => 'xpto',
      meta  => {
        options => [{id => 'a', name => 'AA'}, {id => 'b', name => 'BB'}],
        cls_field_html => 'x y z'
      }
    ),
    qr{<select },
    qr{name="xpto"},
    qr{id="xpto"},
    qr{class="x y z"},
    qr{<option value="a">AA</option>},
    qr{<option value="b">BB</option>},
  );

  like_all(
    'xpto select',
    $c1->render_field_write(
      field => 'xpto',
      meta =>
        {options => [{id => 'a', name => 'A'}, {id => 'b', name => 'B'}]},
      item => {xpto => 'b'},
    ),
    qr{<select },
    qr{name="xpto"},
    qr{id="xpto"},
    qr{<option value="a">A</option>},
    qr{<option value="b" selected="1">B</option>},
  );
};


subtest 'field values', sub {
  my $now  = DateTime->now;
  my $mock = Test::MockObject->new;
  $mock->set_always(stamp => $now);
  $mock->set_always(title => 'aa');

  my $c1 = _ctx();

  is($c1->field_value('stamp'), undef, 'Field stamp not present');
  is($c1->field_value_str('stamp', {data_type => 'date'}),
    '', '... string version is a empty string');

  is($c1->field_value('stamp2', $mock),
    undef, 'Field stamp2 not found in item arg');

  is($c1->field_value('stamp', $mock), $now, 'Field stamp found in item arg');
  is($c1->field_value_str('stamp', {data_type => 'date'}, $mock),
    $now->ymd('/'), '... string version == current date');
  is(
    $c1->field_value_str('stamp', {data_type => 'datetime'}, $mock),
    join(' ', $now->ymd('/'), $now->hms),
    '... string version == current date/time'
  );

  is(
    $c1->field_value_str(
      'stamp',
      { data_type => 'datetime',
        formatter => sub { $_->datetime }
      },
      $mock
    ),
    $now->datetime,
    'Formatter works'
  );

  is(
    $c1->field_value_str(
      'count',
      { data_type => 'int',
        formatter => sub {"xpto $_"}
      },
      {count => 42},
    ),
    "xpto 42",
    'Formatter works for values > 0'
  );

  is(
    $c1->field_value_str(
      'count',
      { data_type => 'int',
        formatter => sub {"xpto $_"}
      },
      {count => 0},
    ),
    "xpto 0",
    'Formatter works for zero values'
  );

  is(
    $c1->field_value_str(
      'count',
      { data_type => 'int',
        formatter => sub {"xpto $_"}
      },
      {count => undef},
    ),
    '',
    'Formatter is not called for undef'
  );

  is($c1->field_value_str('count', {data_type => 'int'}, {count => 42}),
    42, 'Formatter works for values > 0');

  is($c1->field_value_str('count', {data_type => 'int'}, {count => 0}),
    0, 'Formatter works for zero values');

  is($c1->field_value_str('count', {data_type => 'int'}, {count => undef}),
    '', 'Formatter is not called for undef');

  is($c1->field_value('title', $mock), 'aa', 'Field title found in item arg');
  is($c1->field_value_str('title', {data_type => 'char'}, $mock),
    'aa', 'Field title found in item arg');
  is($c1->field_value('title', {title => 'aa'}),
    'aa', 'Field title found in item arg');
  is($c1->field_value_str('title', {data_type => 'char'}, {title => 'aa'}),
    'aa', 'Field title found in item arg');

  is($c1->field_value('stamp', {stamp => $now}),
    $now, 'Field found in item arg');
  is($c1->field_value_str('stamp', {data_type => 'date'}, {stamp => $now}),
    $now->ymd('/'), '... string version == current date');
  is(
    $c1->field_value_str('stamp', {data_type => 'datetime'}, {stamp => $now}),
    join(' ', $now->ymd('/'), $now->hms),
    '... string version == current date/time'
  );

  $c1 = _ctx(item => $mock);

  is($c1->field_value('stamp'), $now, 'Field stamp found in ctx item');
  is($c1->field_value_str('stamp', {data_type => 'date'}),
    $now->ymd('/'), '... string version == current date');
  is(
    $c1->field_value_str('stamp', {data_type => 'datetime'}),
    join(' ', $now->ymd('/'), $now->hms),
    '... string version == current date/time'
  );

  is($c1->field_value('stamp2'), undef, 'Field stamp2 not found in ctx item');

  is($c1->field_value('title'),     'aa', 'Field title found in item arg');
  is($c1->field_value_str('title'), 'aa', 'Field title found in item arg');

  is($c1->field_value_str('t', {}, {}, 1), '', 'Field t not found');
  is($c1->field_value_str('t', {default_value => 5}, {}, 1),
    5, 'Field t not found but default value');
};


done_testing();

sub like_all {
  my $prefix = shift;
  my $text   = shift;

  ### Make sure Test::Builder reports errors in the proper place
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  ok($text, "Got $prefix");
  for my $re (@_) {
    like($text, $re, "... matches $re");
  }
}
