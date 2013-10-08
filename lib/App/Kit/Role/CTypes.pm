package App::Kit::Role::CTypes;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

has ctypes => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require App::Kit::Facade::CTypes;
        return App::Kit::Facade::CTypes->new();
    },
);

1;
