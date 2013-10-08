package App::Kit::Role::String;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

has string => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require App::Kit::Facade::String;
        return App::Kit::Facade::String->new();
    },
);

1;
