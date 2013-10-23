package App::Kit::cPanel;

## no critic (RequireUseStrict) - Moo does strict and warnings
use Moo;
extends 'App::Kit';

has '+log' => (
    is => ( $ENV{'App-Kit_RW'} ? 'rw' : 'rwp' ),
    lazy    => 1,
    default => sub {
        require Cpanel::Logger;
        return Cpanel::Logger->new();
    },
);

has '+locale' => (
    is => ( $ENV{'App-Kit_RW'} ? 'rw' : 'rwp' ),
    lazy    => 1,
    default => sub {
        require Cpanel::Locale;
        return Cpanel::Locale->get_handle();
    },
);

1;

__END__

=encoding utf-8

=head1 App::Kit for cPanel servers. 

Uses cPanel’s logger and locale systems for log() and locale() respectively.

See L<App::Kit> for details.
