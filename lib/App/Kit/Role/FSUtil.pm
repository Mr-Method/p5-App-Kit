package App::Kit::Role::FSUtil;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

has fsutil => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require App::Kit::Facade::FSUtil;
        return App::Kit::Facade::FSUtil->new( { _app => $_[0] } );
    },
);

1;
