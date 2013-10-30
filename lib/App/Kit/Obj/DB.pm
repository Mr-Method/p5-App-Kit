package App::Kit::Obj::DB;

## no critic (RequireUseStrict) - Moo does strict
use Moo;

our $VERSION = '0.1';

Sub::Defer::defer_sub __PACKAGE__ . '::conn' => sub {
    require DBI;
    return sub {
        my ( $self, @connect ) = @_;

        my $dbh = DBI->connect(@connect) || die "Could not connect to database: " . DBI->errstr();

        # TODO: similar thing for other drivers ?
        if ( $dbh->{Driver}{Name} eq 'mysql' ) {
            $dbh->do('SET CHARACTER SET utf8') or die $dbh->errstr;
            $dbh->do("SET NAMES 'utf8'")       or die $dbh->errstr;

            # This will make sure TZ offsets don't goof your datetime queries.
            #     Human readable results will of course need adjusted (and formatted) (hint: locale->datetime(…))
            #         which they would anyway, this just makes it easier to know you are in a universally sane state:
            # Add UTC via: mysql_tzinfo_to_sql /usr/share/zoneinfo/ | mysql -u root mysql -p
            $dbh->do(q{SET time_zone = 'UTC'});    # or die $dbh->errstr;
        }

        return $dbh;
    };
};

has _app => (
    is       => 'ro',
    required => 1,
);

has _dbh => (
    is => 'rwp',

    # isa => sub { die "'_dbh' must be a DBI::db object\n" unless ref $_[0] eq 'DBI::db' },
    default => sub { undef },
);

sub disconn {
    my ( $self, $dbh ) = @_;

    if ($dbh) {
        return 2 if !$dbh->ping;
        $dbh->disconnect || return;
    }
    else {
        if ( defined $self->_dbh ) {
            if ( !$self->_dbh->ping ) {
                $self->_set__dbh(undef);
                return 2;
            }
            $self->_dbh->disconnect || return;
        }
        $self->_set__dbh(undef);
    }

    return 1;
}

Sub::Defer::defer_sub __PACKAGE__ . '::dbh' => sub {
    require DBI;
    return sub {
        my ( $self, $dbi_conf ) = @_;

        if ( !$self->_dbh || !$self->_dbh->ping ) {    # TODO: only ping() every N calls/seconds
            if ( !$dbi_conf ) {
                my $file = $self->_app->fs->file_lookup( 'config', 'db.conf' );
                if ($file) {
                    $dbi_conf = {};                    # TODO: sort out conf file methods  (or Config::Any etc): $self->_app->fs->read_json($file);
                }
                else {
                    die "no dbi_conf in arguments or app configuration\n";
                }
            }

            $dbi_conf->{'host'} ||= 'localhost';

            my @connect = (
                "DBI:$dbi_conf->{'dbd_driver'}:database=$dbi_conf->{'database'};host=$dbi_conf->{'host'};" . join( ';', map { "$_=$dbi_conf->{'dsn_attr'}{$_}" } sort keys %{ $dbi_conf->{'dsn_attr'} } ),    # TODO/YAGNI: dictate order ?
                $dbi_conf->{'user'} || '',
                $dbi_conf->{'pass'} || '',
                $dbi_conf->{'connect_attr'},
            );

            $self->_set__dbh( $self->conn(@connect) );
        }

        return $self->_dbh;
    };
};

1;

__END__

=encoding utf-8

=head1 NAME

App::Kit::Obj::Db - database utility object

=head1 VERSION

This document describes App::Kit::Obj::DB version 0.1

=head1 SYNOPSIS

    my $db = App::Kit::Obj::DB->new(…);
    $db->dbh()->…

=head1 DESCRIPTION

database utility object

=head1 INTERFACE

=head2 new()

Returns the object.

Takes one required attribute: _app. It should be an L<App::Kit> object for it to use internally.

Takes one optional and discouraged attribute: _dbh. Should be a L<DBI::db> object.

=head2 dbh()

Returns the main database handle for our app. Reconnecting if necessary.

Lazy loads L<DBI> the first time it is called.

The connection you want is defined via a hashref with the following keys:

=over 4

=item 'dbd_driver' (required)

e.g. SQLite, mysql

=item 'database' (required)

=item 'host' (defaults to 'localhost')

=item 'dsn_attr'

hashref of additional DSN keys and values (built sorted by key)

    { port => 1234 }

=item 'user' (defaults to '')

=item 'pass' (defaults to '')

=item 'connect_attr'

hashref that corresponds to the 4th argument to DBI->connect;

=back

The connections hashref can be given in two ways:

=over 4

=item 1. As the only argument to dbh

    $db->dbh({…})

=item 2. In you app’s config/db.conf

    $db->dbh()

More info on this will be in the next version.

=back

=head2 conn()

Shortcut to DBI->connect(…) or die ….

Takes the same arguments as DBI->connect.

For mysql based objects it additionally does some setup to ensure we’re speaking utf-8 and that datetime operations are normalized to UTC.

Lazy loads L<DBI> the first time it is called.

=head2 disconn()

When given no arguments it disconnects and undefines the main database handle (i.e. the one via dbh()).

When given a database handle (e.g. one from conn()) it disconnects that.

Returns 2 if it is already disconnected.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<DBI>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
