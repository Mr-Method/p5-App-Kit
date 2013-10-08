package App::Kit::Facade::DB;

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
    is      => 'rwp',
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
