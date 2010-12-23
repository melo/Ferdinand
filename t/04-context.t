#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::MockObject;
use Ferdinand::Context;
use Ferdinand::Action;
use DateTime;
use URI;

my $map    = bless {}, 'Ferdinand::Map';
my $action = bless {}, 'Ferdinand::Action';

my $ctx;
is(
  exception {
    $ctx = Ferdinand::Context->new(
      map        => $map,
      action     => $action,
      action_uri => URI->new('http://example.com/something'),
      uri_helper => sub { join(' ', @_) },
      params     => {a => 1, b => 2},
      stash      => {x => 9, y => 8},
    );
  },
  undef,
  'Created context and lived'
);

isa_ok($ctx->map,        'Ferdinand::Map');
isa_ok($ctx->action,     'Ferdinand::Action');
isa_ok($ctx->action_uri, 'URI');

is($ctx->widget, undef,    'Widget is undef');
is($ctx->uri(5), "$ctx 5", 'uri_helper works');

is($ctx->action_uri->path, '/something', 'action_uri works');

cmp_deeply($ctx->params, {a => 1, b => 2}, 'param as expected');
cmp_deeply($ctx->stash,  {x => 9, y => 8}, 'stash as expected');

is($ctx->mode, 'view', 'mode as expected');


subtest 'context cloning' => sub {
  is($ctx->parent, undef, 'parent is undef');
  $ctx->buffer('a1');
  is($ctx->buffer, 'a1', 'Buffer has something in it');

  is($ctx->item, undef, 'Item is undef by default');
  is($ctx->set,  undef, 'Set is undef by default');

  subtest 'test cloned context' => sub {
    my $c1 = $ctx->clone;
    isnt($ctx, $c1, 'Clone returns a new object');
    is($c1->parent, $ctx, "... parent is old context");
    isa_ok($c1, 'Ferdinand::Context');

    cmp_deeply($c1->params, {a => 1, b => 2}, 'cloned param as expected');
    cmp_deeply($c1->stash,  {x => 9, y => 8}, 'cloned stash as expected');

    for my $attr (qw( map action widget uri_helper )) {
      is($c1->$attr, $ctx->$attr, "Cloned context '$attr' is the same");
    }

    $c1->item(bless({a => 1, b => 2}, 'X'));
    $c1->set(bless([{a => 1}, {a => 2}], 'X'));
    cmp_deeply(
      $c1->item,
      bless({a => 1, b => 2}, 'X'),
      'Item set as expected'
    );
    cmp_deeply(
      $c1->set,
      bless([{a => 1}, {a => 2}], 'X'),
      'Set updated as expected'
    );

    is($c1->buffer, '', 'Cloned context buffer is empty');
    $c1->buffer('a2');
    is($c1->buffer, 'a2', '... buffer updated properly');

    is($c1->parent->buffer, 'a1', 'Parent ctx still has the original buffer');
  };

  subtest 'test cloned with args' => sub {
    my $c1 = $ctx->clone(params => {p1 => 1, p2 => 2});

    cmp_deeply(
      $c1->params,
      {p1 => 1, p2 => 2},
      'cloned params with new values'
    );
    cmp_deeply($c1->stash, {x => 9, y => 8}, 'cloned stash as previous');
  };

  is($ctx->buffer, 'a1a2', 'Cloned context updated');

  is($ctx->item, undef, 'Item is undef again');
  is($ctx->set,  undef, 'Set is undef again');

  cmp_deeply($ctx->params, {a => 1, b => 2}, 'params still as expected');
};


subtest 'context overlay' => sub {
  is($ctx->parent, undef, 'parent is undef');
  $ctx->buffer('a1');
  is($ctx->buffer, 'a1a2a1', 'Buffer has something in it');

  is($ctx->item, undef, 'Item is undef by default');
  is($ctx->set,  undef, 'Set is undef by default');

  cmp_deeply($ctx->params, {a => 1, b => 2}, 'base param as expected');
  cmp_deeply($ctx->stash,  {x => 9, y => 8}, 'base stash as expected');

  subtest 'test overlay context' => sub {
    my $g =
      $ctx->overlay(set => bless([{a => 1}, {a => 2}], 'X'), stash => {});

    cmp_deeply(
      $ctx->set,
      bless([{a => 1}, {a => 2}], 'X'),
      'Set with new value from overlay'
    );

    cmp_deeply($ctx->params, {a => 1, b => 2}, 'overlay param as expected');
    cmp_deeply($ctx->stash, {}, 'overlay stash as expected');

    is($ctx->buffer, 'a1a2a1', 'Overlayed buffer is the same');
    $ctx->buffer('a2');
    $ctx->item(bless({a => 1, b => 2}, 'X'));
  };

  is($ctx->buffer, 'a1a2a1a2', 'Buffer as expected after overlay cleanup');

  cmp_deeply(
    $ctx->item,
    bless({a => 1, b => 2}, 'X'),
    'Item as expected after overlay cleanup'
  );
  cmp_deeply($ctx->stash, {x => 9, y => 8},
    'Stash back to pre-overlay value');
  is($ctx->set, undef, 'Set back to pre-overlay value');
};


subtest 'context stash' => sub {
  cmp_deeply($ctx->stash, {x => 9, y => 8}, 'Stash as expected');

  my $s = $ctx->stash(b => undef, c => 3);
  is($s, $ctx->stash, 'stash() returs the hashref');
  cmp_deeply($s, {c => 3, x => 9, y => 8}, 'Stash modified as expected');
  $ctx->stash(c => undef, d => 4);
  cmp_deeply($s, {d => 4, x => 9, y => 8}, 'Stash modified as expected');
};


subtest 'buffer management' => sub {
  my $c1 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
  );

  is($c1->buffer, '', 'Buffer is empty from the start');

  $c1->buffer('a', 'b', 'c');
  is($c1->buffer, 'abc', '... and now its no longer empty');

  $c1->buffer('A', 'B', 'C');
  is($c1->buffer, 'abcABC', '... concat works');

  my $b = $c1->clear_buffer;
  is($c1->buffer, '',       'Buffer is empty again');
  is($b,          'abcABC', '... and the old buffer is returned');
};


subtest 'render_field output' => sub {
  my $i = Test::MockObject->new;
  $i->set_always(v  => '<abcd & efgh>');
  $i->set_always(e  => '!!');
  $i->set_always(id => 1);

  my $c1 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
    item   => $i,
  );

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

  $c1 = $c1->clone(uri_helper => sub { return join('/', @{$_[1]}) });
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
  my $c1 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
  );

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
  my $c1 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
  );

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


subtest 'buffer stack', sub {
  my $c1 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
  );

  is($c1->buffer, '', 'Buffer empty at the start');

  $c1->buffer('aa');
  is($c1->buffer, 'aa', 'Buffer modification ok');

  $c1->buffer_stack;
  is($c1->buffer, '', 'Buffer is empty once more');

  $c1->buffer('bb');
  $c1->buffer_merge;
  is($c1->buffer, 'aabb', 'Buffer merging ok');

  $c1->buffer_stack('cc');
  is($c1->buffer, 'cc', 'Buffer with proper value');

  $c1->buffer_stack('dd');
  is($c1->buffer, 'dd', 'Buffer with proper value again');

  $c1->buffer_merge('111');
  $c1->buffer_merge;
  is($c1->buffer, 'aabbccdd111', 'Buffer ok');
};


subtest 'buffer wrap', sub {
  my $c1 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
  );

  is($c1->buffer,       '',   'Buffer empty at the start');
  is($c1->buffer('aa'), 'aa', 'Buffer not empty');

  $c1->buffer_wrap('pp');
  is($c1->buffer, 'ppaa', 'Buffer with prepended stuff');

  $c1->buffer_wrap(undef, 'pp');
  is($c1->buffer, 'ppaapp', 'Buffer with appended stuff');

  $c1->buffer_wrap('<p>', '</p>');
  is($c1->buffer, '<p>ppaapp</p>', 'Buffer wrapped');
};


subtest 'buffers and parentage', sub {
  my $c1 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
  );

  my $c2 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
    parent => $c1,
  );

  $c1->buffer('aa');
  $c2->buffer('bb');
  undef $c2;

  is($c1->buffer, 'aabb', 'Buffer after parent merge ok');

  is(exception { undef $c1 }, undef, 'No parent, no die');
};


subtest 'field values', sub {
  my $now  = DateTime->now;
  my $mock = Test::MockObject->new;
  $mock->set_always(stamp => $now);
  $mock->set_always(title => 'aa');

  my $c1 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
  );

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

  $c1 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
    item   => $mock,
  );

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


subtest 'error mgmt', sub {
  my $c1 = Ferdinand::Context->new(
    map    => $map,
    action => $action,
  );

  ok(!$ctx->has_errors, 'No errors on new contexts');
  cmp_deeply([$ctx->errors], [], '... so empty kv for errors');
  is($ctx->error_for('x'), undef, 'No error for x field');

  $ctx->add_error(x => 42);
  ok($ctx->has_errors, 'Found errors in context');
  is($ctx->error_for('x'), 42, '... found error for x field');
  cmp_deeply([$ctx->errors], [[x => 42]], '... kv has proper errors');

  $ctx->add_error(x => 84);
  ok($ctx->has_errors, 'Found errors in context');
  is($ctx->error_for('x'), 84, '... found error for x field');
  cmp_deeply([$ctx->errors], [[x => 84]], '... kv has proper errors');

  $ctx->clear_errors;
  ok(!$ctx->has_errors, 'No errors after clear_errors()');
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
