package App::Kit::Role::CType;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

our $VERSION = '0.1';

has ctype => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require App::Kit::Facade::CType;
        return App::Kit::Facade::CType->new();
    },
);

1;
