package App::Kit::Role::NSUtil;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

has nsutil => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require App::Kit::Facade::NSUtil;
        return App::Kit::Facade::NSUtil->new( { base => $_[0] } );
    },
);

1;
