package App::Kit::Role::FS;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

our $VERSION = '0.1';

has fs => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require App::Kit::Facade::FS;
        return App::Kit::Facade::FS->new( { _app => $_[0] } );
    },
);

1;
