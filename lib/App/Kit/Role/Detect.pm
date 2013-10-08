package App::Kit::Role::Detect;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

has detect => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require App::Kit::Facade::Detect;
        return App::Kit::Facade::Detect->new();
    },
);

1;
