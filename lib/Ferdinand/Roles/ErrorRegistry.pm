package Ferdinand::Roles::ErrorRegistry;

use Ferdinand::Setup 'role';
use namespace::clean -except => 'meta';


##################
# Error management

has 'errors' => (
  traits  => ['Hash'],
  is      => 'bare',
  isa     => 'HashRef',
  default => sub { {} },
  handles => {
    add_error    => 'set',
    error_for    => 'get',
    has_errors   => 'count',
    errors       => 'kv',
    clear_errors => 'clear',
  },
);


1;
