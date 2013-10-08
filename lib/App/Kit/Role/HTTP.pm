package App::Kit::Role::HTTP;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

our $VERSION = '0.1';

has http => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require HTTP::Tiny;
        eval { require HTTP::Tiny::Multipart };    # enable multipart support if possible, otherwise be silent
        return HTTP::Tiny->new();
    },
);

1;
