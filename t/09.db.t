use Test::More;
use Test::Exception;

use App::Kit;

diag("Testing db() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

my $dir      = $app->fs->tmpdir();
my $sqlite_x = $app->fs->spec->catdir( $dir, 'extra_db' );
my $sqlite_m = $app->fs->spec->catdir( $dir, 'main_db' );

ok( !exists $INC{'DBI.pm'}, 'Sanity: DBI not loaded before conn()' );
my $x_dbh = $app->db->conn("DBI:SQLite:$sqlite_x");    # no need for  "", "" w/ SQLite as that is the default! # Perl::DependList-IS_DEP(DBD::SQLite)
isa_ok( $x_dbh, 'DBI::db', 'conn() meth returns dbh' );
ok( exists $INC{'DBI.pm'}, 'DBI lazy loaded on initial conn()' );

my $m_dbh;
{
    # DBI can no teasily be unloaded so we do that test in another test file
    $m_dbh = $app->db->dbh( { 'database' => $sqlite_m, 'dbd_driver' => 'SQLite' } );    # Perl::DependList-IS_DEP(DBD::SQLite)
    isa_ok( $m_dbh, 'DBI::db', 'dbh() meth returns dbh' );
    is( $m_dbh, $app->db->dbh(), 'dbh() returns same object' );
}

################
##### disconn ##
################

ok( $x_dbh->ping,              'sanity: x_dbh is connected' );
ok( $app->db->disconn($x_dbh), 'disconn($dbh) returns true when it works' );
ok( !$x_dbh->ping,             'disconn($dbh) disconnects given handle' );
ok( $m_dbh->ping,              'disconn($dbh) does not disconnect main handle' );
is( $app->db->disconn($x_dbh), 2, 'disconn($dbh) returns 2 when it is already disconnected' );

ok( $app->db->disconn(), 'disconn() returns true when it works' );
ok( !$m_dbh->ping,       'disconn() disconnects main handle' );
is( $app->db->_dbh, undef, 'disconn() undefines main handle' );

###############################################
#### mysql driver tests (e.g. conn() extras) ##
###############################################

{
    my @mysql;
    no warnings 'redefine';
    no warnings 'once';
    local *DBI::connect = sub { return bless { Driver => { Name => 'mysql' } }, 'DBI' };
    local *DBI::do = sub { shift; push @mysql, shift; };
    $app->db->conn;
    is_deeply(
        \@mysql,
        [
            'SET CHARACTER SET utf8',
            "SET NAMES 'utf8'",
            "SET time_zone = 'UTC'"
        ],
        'conn() w/ mysql driver does expected queries'
    );

    @mysql = ();
    *DBI::connect = sub { return bless { Driver => { Name => 'fooo' } }, 'DBI' };
    $app->db->conn;
    is_deeply( \@mysql, [], 'conn() w/ non-mysql driver does not do mysql specific queries' );
}

########################################
#### test dbh()’s connection building ##
########################################

{
    no warnings 'redefine';
    no warnings 'once';
    local *App::Kit::Obj::DB::_set__dbh = sub { };
    my @e = ( 'DBI:foo:database=mydb;host=localhost;', '', '', undef );
    my $n = 'min req keys';
    local *App::Kit::Obj::DB::conn = sub {
        my ( $o, @c ) = @_;
        is_deeply( \@c, [@e], "dbh() conn builder: $n" );
    };
    $app->db->dbh( { dbd_driver => "foo", database => "mydb", } );

    throws_ok { $app->db->dbh() } qr/no dbi_conf in arguments or app configuration/, 'dbh() no args caught OK';

    # # these are actually uninit  warnings but strictures are on in Moo tests (TODO: a better way?)
    dies_ok { $app->db->dbh( {} ) } 'dbh() empty hash ref';
    dies_ok { $app->db->dbh( { dbd_driver => "fooo" } ) } 'dbh() only dbd_driver';
    dies_ok { $app->db->dbh( { database => "medb" } ) } 'dbh() only database';

    @e = ( 'DBI:foo:database=mydb;host=localhost;', 'usr', 'pss', undef );
    $n = 'user pass';
    $app->db->dbh( { dbd_driver => "foo", database => "mydb", user => "usr", pass => "pss" } );

    @e = ( 'DBI:foo:database=mydb;host=myhost;', '', '', undef );
    $n = 'given host';
    $app->db->dbh( { dbd_driver => "foo", database => "mydb", host => "myhost" } );

    @e = ( 'DBI:foo:database=mydb;host=localhost;', '', '', { foo => 42, bar => 99 } );
    $n = 'connect_attr';
    $app->db->dbh( { dbd_driver => "foo", database => "mydb", connect_attr => { foo => 42, bar => 99 } } );

    @e = ( 'DBI:foo:database=mydb;host=localhost;dsn=99', '', '', undef );
    $n = 'dsn_attr';
    $app->db->dbh( { dbd_driver => "foo", database => "mydb", dsn_attr => { dsn => 99 } } );

    @e = ( 'DBI:foo:database=mydb;host=localhost;dsn=99;foo=78', '', '', undef );
    $n = 'dsn_attr';
    $app->db->dbh( { dbd_driver => "foo", database => "mydb", dsn_attr => { dsn => 99, foo => 78 } } );
}

#########################
## tests via conf file ##
#########################

# TODO: sort out conf file methods  (or Config::Any etc)
# $app->fs->bindir($dir);
# my $sqlite_f = $app->fs->spec->catdir( $dir, 'conf_db');
# my $conf_file = $app->fs->spec->catdir( $dir, 'config', 'db.conf');
# $app->fs->mk_parent($conf_file);
# $app->fs->write_json($conf_file, {dbd_driver=>'SQLite', database=>$sqlite_f});
#
# $app->db->disconn;
# is($app->db->_dbh, undef, 'sanity main DBH not set');
# isa_ok($app->db->dbh(), 'DBI::db', 'dbh() connected via conf file data');
# is($app->db->dbh()->{Driver}{Name} eq 'SQlite', 'connecetd conf is correct driver');

done_testing;
