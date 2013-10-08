package App::Kit::Role::NS;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

our $VERSION = '0.1';

has ns => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require App::Kit::Facade::NS;
        return App::Kit::Facade::NS->new( { base => $_[0] } );
    },
);

1;
