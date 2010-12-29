package Ferdinand::Tests::Helpers;

use Ferdinand::Setup 'library';
use Ferdinand;
use Ferdinand::Context;
use Ferdinand::Utils qw( load_widget );
use Method::Signatures;
use Test::More  ();
use Test::Fatal ();
use lib 't/tlib';
use DateTime;
use URI;

@Ferdinand::Tests::Helpers::EXPORT = qw(
  build_ctx
  setup_widget
  render_ok
  test_db
  require_tenjin
);

func build_ctx () {
  my @extra_args = @_;
  my $ctx;

  Test::More::is(
    Test::Fatal::exception {
      $ctx = Ferdinand->build_ctx({
        action_uri => URI->new('http://example.com/something'),
        @extra_args,
      });
    },
    undef,
    'Context created, no exceptions'
  );

  return $ctx;
}


func setup_widget ($widget, $meta = {}) {
  eval { $widget = load_widget($widget) };
  return Ferdinand->setup($widget, $meta) unless $@;

  Test::More::plan skip_all => "Failed to load widget '$widget': $@";
}


func render_ok ($widget, $args = {}, $message = '') {
  $message = "Render called on $widget, no exception" unless $message;
  $args->{action_uri} = URI->new('http://example.com/something')
    unless $args->{action_uri};

  my $ctx;
  Test::More::is(
    Test::Fatal::exception { $ctx = Ferdinand->render($widget, $args) },
    undef, $message);

  return $ctx;
}


func test_db () {
  my $db;
  eval { require TDB; $db = TDB->test_deploy() };
  Test::More::plan skip_all =>
    "Could not load test database, probably missing DBIC: $@"
    if $@;

  return $db;
}


func require_tenjin () {
  eval "require Tenjin::Engine";
  Test::More::plan skip_all => "Skip this tests unless we can find original plTenjin: $@"
    if $@;
}

1;
