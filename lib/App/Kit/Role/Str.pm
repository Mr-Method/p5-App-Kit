package App::Kit::Role::Str;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

our $VERSION = '0.1';

has str => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require App::Kit::Facade::Str;
        return App::Kit::Facade::Str->new();
    },
);

1;
