use Test::More;
use Class::Unload;

use App::Kit;

diag("Testing db() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

my $dir = $app->fs->tmpdir();
my $sqlite = $app->fs->spec->catdir( $dir, 'db' );

ok( !exists $INC{'DBI.pm'}, 'Sanity: DBI not loaded before dbh()' );
my $m_dbh = $app->db->dbh( { 'database' => $sqlite, 'dbd_driver' => 'SQLite' } );
ok( exists $INC{'DBI.pm'}, 'DBI lazy loaded on initial dbh()' );
isa_ok( $m_dbh, 'DBI::db', 'dbh() meth returns dbh' );
is( $m_dbh, $app->db->dbh(), 'dbh() returns same object' );

done_testing;
