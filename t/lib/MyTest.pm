package MyTest;

use Moo;

extends 'App::Kit';

has foo => ( is => "ro", default => sub { return 42 } );

sub bar { return 23 }

has '+logger' => (
    default => sub { "busted logger" },
);

1;
