package App::Kit::Role::Locale;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

our $VERSION = '0.1';

has locale => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require Locale::Maketext::Utils::Mock;
        return Locale::Maketext::Utils::Mock->get_handle();
    },
);

1;
