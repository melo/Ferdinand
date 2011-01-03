#!perl

use strict;
use warnings;
use Ferdinand::Tests;
use Ferdinand::Model;
use Test::MockObject;

subtest 'field metadata' => sub {
  my $f1 = Ferdinand::Model->new;

  cmp_deeply($f1->field_meta('v'), {},
    'Metadata for unknwon field is a empty hash');

  $f1->set_field_meta(v => {a => 1});
  cmp_deeply(
    $f1->field_meta('v'),
    {a => 1, _file => ignore(), _line => ignore()},
    'Metadata retrieval works'
  );

  like(
    exception { $f1->set_field_meta(v => {a => 1}) },
    qr/Field 'v' already exists/,
    'Exception thrown for dup set_field_meta'
  );
};


subtest 'render_field output' => sub {
  my $i = Test::MockObject->new;
  $i->set_always(v  => '<abcd & efgh>');
  $i->set_always(e  => '!!');
  $i->set_always(id => 1);

  my $c1 = build_ctx(item => $i, model => Ferdinand::Model->new);

  my %args = (field => 'v');
  my %meta;
  $c1->model->set_field_meta(v => \%meta);

  is($c1->render_field(%args), '&lt;abcd &amp; efgh&gt;', 'Single row value');

  $meta{formatter} = sub { return uc($_) };
  is(
    $c1->render_field(%args),
    '&lt;ABCD &amp; EFGH&gt;',
    'Single row value, with formatter'
  );

  $meta{cls_field_html} = 'x y z';
  is(
    $c1->render_field(%args),
    '<span class="x y z">&lt;ABCD &amp; EFGH&gt;</span>',
    'Single row value, with class'
  );

  $meta{link_to} = sub { $_->e };
  like_all(
    'link_to value + class',
    $c1->render_field(%args),
    qr{^<a }, qr{ class="x y z"},
    qr{ href="!!"}, qr{>&lt;ABCD &amp; EFGH&gt;</a>},
  );

  delete $meta{cls_field_html};
  $meta{link_to} = sub { $_->e };
  is(
    $c1->render_field(%args),
    '<a href="!!">&lt;ABCD &amp; EFGH&gt;</a>',
    'link_to value'
  );

  $meta{linked} = ['view', 'me'];
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
    $c1->render_field(field => 'x', item => $i),
    '&lt;ABCD &amp; EFGH&gt;',
    'Override item on render_field ok'
  );

  $c1->model->set_field_meta(x => {format => 'html'});
  is(
    $c1->render_field(field => 'x', item => $i),
    '<div class="html_fmt"><ABCD & EFGH></div>',
    'HTML format in fields renders ok'
  );

  ## Check influence of modes with render_field
  my $mock_42 = Test::MockObject->new;
  $mock_42->set_always(x => '42');

  for my $item ({x => '42'}, $mock_42) {
    for my $m (qw( view list )) {
      my $c2 = build_ctx(mode => $m, model => Ferdinand::Model->new);
      is($c2->render_field(field => 'x', item => $item),
        '42', "Proper render_field() output for mode '$m' (item $item)");
    }
    for my $m (qw( create create_do edit edit_do )) {
      my $c2 = build_ctx(mode => $m, model => Ferdinand::Model->new);
      like_all(
        "Proper render_field() output for mode '$m' (item $item)",
        $c2->render_field(field => 'x', item => $item),
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
  my $c1 = build_ctx(model => Ferdinand::Model->new);
  my %meta;
  $c1->model->set_field_meta(xpto => \%meta);

  is($c1->render_field_read(field => 'xpto'), '', 'xpto bare input');
  is($c1->render_field_read(field => 'xpto', item => {xpto => 'aa'}),
    'aa', 'xpto with previous value');

  %meta = (cls_field_html => 'x y z');
  is(
    $c1->render_field_read(
      field => 'xpto',
      item  => {xpto => 'aa'}
    ),
    '<span class="x y z">aa</span>',
    'xpto with previous value + class'
  );

  %meta = (is_nullable => 1);
  is($c1->render_field_read(field => 'xpto'),
    '', 'xpto with meta for optional file');

  %meta = (data_type => 'date');
  is(
    $c1->render_field_read(
      field => 'xpto',
      item  => {xpto => DateTime->new(year => 2001, month => 9, day => 10)},
    ),
    '2001/09/10',
    'xpto with meta type date',
  );

  %meta = (data_type => 'char', size => 10);
  is(
    $c1->render_field_read(
      field => 'xpto',
      item  => {xpto => 'yuppi'}
    ),
    'yuppi',
    'xpto with meta type char with size'
  );

  %meta = (data_type => 'varchar');
  is($c1->render_field_read(field => 'xpto'),
    '', 'xpto with meta type varchar');

  %meta = (data_type => 'text');
  is($c1->render_field_read(field => 'xpto'),
    '<div></div>', 'xpto text field');

  %meta = (data_type => 'text', cls_field_html => 'x y z');
  is(
    $c1->render_field_read(field => 'xpto'),
    '<div class="x y z"></div>',
    'xpto text field + class'
  );

  %meta = (data_type => 'text', cls_field_html => 'x y z', format => 'html');
  is(
    $c1->render_field_read(
      field => 'xpto',
      item  => {xpto => '<br>'}
    ),
    '<div class="x y z html_fmt"><br></div>',
    'xpto text field, HTML formatted + class'
  );

  %meta = (data_type => 'text');
  is(
    $c1->render_field_read(
      field => 'xpto',
      item  => {xpto => 'yyy'},
    ),
    '<div>yyy</div>',
    'xpto text field + value'
  );

  %meta = (options => [{id => 'a', name => 'A'}, {id => 'b', name => 'B'}]);
  is($c1->render_field_read(field => 'xpto'),
    '', 'xpto field with options, no value');

  %meta = (
    options => [{id => 'a', name => 'AA'}, {id => 'b', name => 'BB'}],
    cls_field_html => 'x y z'
  );
  is(
    $c1->render_field_read(field => 'xpto'),
    '<span class="x y z"></span>',
    'xpto field with options + class'
  );

  %meta = (options => [{id => 'a', name => 'A'}, {id => 'b', name => 'B'}]);
  is(
    $c1->render_field_read(
      field => 'xpto',
      item  => {xpto => 'b'},
    ),
    'B',
    'xpto field with options + value'
  );
};


subtest 'render_field_write', sub {
  my $c1 = build_ctx(model => Ferdinand::Model->new);
  my %meta;
  $c1->model->set_field_meta(xpto => \%meta);

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

  %meta = (empty => 1);
  like_all(
    'xpto with previous value + empty meta => empty',
    $c1->render_field_write(
      field => 'xpto',
      item  => {xpto => 'aa'}
    ),
    qr{<input },
    qr{type="text"},
    qr{name="xpto"},
    qr{id="xpto"},
    qr{required="1"},
    qr{value=""},
  );

  %meta = (cls_field_html => 'x y z');
  like_all(
    'xpto with previous value + class',
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
    qr{class="x y z"},
  );

  %meta = (is_nullable => 1);
  like_all(
    'xpto with meta for optional file',
    $c1->render_field_write(field => 'xpto'),
    qr{<input }, qr{type="text"}, qr{name="xpto"}, qr{id="xpto"},
  );

  %meta = (data_type => 'date');
  like_all(
    'xpto with meta type date',
    $c1->render_field_write(field => 'xpto'),
    qr{<input }, qr{type="date"}, qr{name="xpto"}, qr{id="xpto"},
  );

  %meta = (data_type => 'char', size => 10);
  like_all(
    'xpto with meta type char with size',
    $c1->render_field_write(field => 'xpto'),
    qr{<input },
    qr{type="text"},
    qr{name="xpto"},
    qr{id="xpto"},
    qr{maxlength="10"},
    qr{size="10"},
  );

  %meta = (data_type => 'char', size => 10, width => 5);
  like_all(
    'xpto with meta type char with size + width',
    $c1->render_field_write(field => 'xpto'),
    qr{<input },
    qr{type="text"},
    qr{name="xpto"},
    qr{id="xpto"},
    qr{maxlength="10"},
    qr{size="5"},
  );

  %meta = (data_type => 'varchar');
  like_all(
    'xpto with meta type varchar',
    $c1->render_field_write(field => 'xpto'),
    qr{<input }, qr{type="text"}, qr{name="xpto"}, qr{id="xpto"},
  );

  %meta = (data_type => 'text');
  like_all(
    'xpto textarea', $c1->render_field_write(field => 'xpto'),
    qr{<textarea },  qr{></textarea>},
    qr{cols="100"},  qr{rows="6"},
    qr{name="xpto"}, qr{id="xpto"},
  );

  %meta = (data_type => 'text', cls_field_html => 'x y z');
  like_all(
    'xpto textarea + class', $c1->render_field_write(field => 'xpto'),
    qr{<textarea },          qr{></textarea>},
    qr{cols="100"},          qr{rows="6"},
    qr{name="xpto"},         qr{id="xpto"},
    qr{class="x y z"},
  );

  %meta = (data_type => 'text', cls_field_html => 'x y z', format => 'html');
  like_all(
    'xpto textarea + class',
    $c1->render_field_write(
      field => 'xpto',
      item  => {xpto => '<br>'},
    ),
    qr{<textarea },
    qr{><br></textarea>},
    qr{cols="100"},
    qr{rows="18"},
    qr{name="xpto"},
    qr{id="xpto"},
    qr{class="x y z html_fmt"},
  );

  %meta = (data_type => 'text');
  like_all(
    'xpto textarea',
    $c1->render_field_write(
      field => 'xpto',
      item  => {xpto => 'yyy'},
    ),
    qr{<textarea },
    qr{>yyy</textarea>},
    qr{cols="100"},
    qr{rows="6"},
    qr{name="xpto"},
    qr{id="xpto"},
  );

  %meta = (options => [{id => 'a', name => 'A'}, {id => 'b', name => 'B'}]);
  like_all(
    'xpto select',
    $c1->render_field_write(field => 'xpto'),
    qr{<select },
    qr{name="xpto"},
    qr{id="xpto"},
    qr{<option value="a">A</option>},
    qr{<option value="b">B</option>},
  );

  %meta = (
    options => [{id => 'a', name => 'AA'}, {id => 'b', name => 'BB'}],
    cls_field_html => 'x y z'
  );
  like_all(
    'xpto select + class',
    $c1->render_field_write(field => 'xpto'),
    qr{<select },
    qr{name="xpto"},
    qr{id="xpto"},
    qr{class="x y z"},
    qr{<option value="a">AA</option>},
    qr{<option value="b">BB</option>},
  );

  %meta = (options => [{id => 'a', name => 'A'}, {id => 'b', name => 'B'}]);
  like_all(
    'xpto select',
    $c1->render_field_write(
      field => 'xpto',
      item  => {xpto => 'b'},
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

  my $c1 = build_ctx(model => Ferdinand::Model->new);
  my $f1 = $c1->model;
  my %meta;
  $f1->set_field_meta(stamp => \%meta);
  $f1->set_field_meta(title => \%meta);
  $f1->set_field_meta(count => \%meta);

  is($c1->field_value(field => 'stamp2', item => $mock),
    undef, 'Field stamp2 not found in item arg');

  %meta = (data_type => 'date');
  is($c1->field_value(field => 'stamp'), undef, 'Field stamp not present');
  is($c1->field_value_str(field => 'stamp'),
    '', '... string version is a empty string');

  is($c1->field_value(field => 'stamp', item => $mock),
    $now, 'Field stamp found in item arg');
  is($c1->field_value_str(field => 'stamp', item => $mock),
    $now->ymd('/'), '... string version == current date');

  %meta = (data_type => 'datetime');
  is(
    $c1->field_value_str(field => 'stamp', item => $mock),
    join(' ', $now->ymd('/'), $now->hms),
    '... string version == current date/time'
  );


  %meta = (data_type => 'datetime', formatter => sub { $_->datetime });
  is($c1->field_value_str(field => 'stamp', item => $mock),
    $now->datetime, 'Formatter works');

  %meta = (
    data_type => 'int',
    formatter => sub {"xpto $_"},
  );
  is($c1->field_value_str(field => 'count', item => {count => 42}),
    "xpto 42", 'Formatter works for values > 0');
  is($c1->field_value_str(field => 'count', item => {count => 0}),
    "xpto 0", 'Formatter works for zero values');
  is($c1->field_value_str(field => 'count', item => {count => undef}),
    '', 'Formatter is not called for undef');

  %meta = (data_type => 'int');
  is($c1->field_value_str(field => 'count', item => {count => 42}),
    42, 'Formatter works for values > 0');
  is($c1->field_value_str(field => 'count', item => {count => 0}),
    0, 'Formatter works for zero values');
  is($c1->field_value_str(field => 'count', item => {count => undef}),
    '', 'Formatter is not called for undef');

  %meta = ();
  is($c1->field_value(field => 'title', item => $mock),
    'aa', 'Field title found in item arg');

  %meta = (data_type => 'char');
  is($c1->field_value_str(field => 'title', item => $mock),
    'aa', 'Field title found in item arg');
  is($c1->field_value(field => 'title', item => {title => 'aa'}),
    'aa', 'Field title found in item arg');
  is($c1->field_value_str(field => 'title', item => {title => 'aa'}),
    'aa', 'Field title found in item arg');


  $c1   = build_ctx(item => $mock, model => Ferdinand::Model->new);
  $f1   = $c1->model;
  %meta = ();
  $f1->set_field_meta(stamp => \%meta);
  $f1->set_field_meta(title => \%meta);
  $f1->set_field_meta(count => \%meta);

  is($c1->field_value(field => 'stamp'),
    $now, 'Field stamp found in ctx item');

  %meta = (data_type => 'date');
  is($c1->field_value_str(field => 'stamp'),
    $now->ymd('/'), '... string version == current date');

  %meta = (data_type => 'datetime');
  is(
    $c1->field_value_str(field => 'stamp'),
    join(' ', $now->ymd('/'), $now->hms),
    '... string version == current date/time'
  );

  is($c1->field_value(field => 'stamp2'),
    undef, 'Field stamp2 not found in ctx item');

  %meta = ();
  is($c1->field_value(field => 'title'),
    'aa', 'Field title found in item arg');
  is($c1->field_value_str(field => 'title'),
    'aa', 'Field title found in item arg');


  is($c1->field_value_str(field => 'count', item => {}, use_default => 1),
    '', 'No value found for field count');

  %meta = (default_value => 5);
  is($c1->field_value_str(field => 'count', item => {}, use_default => 1),
    5, 'Field count not found but default value was used');
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
