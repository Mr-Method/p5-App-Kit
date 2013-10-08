use Test::More;
use Test::Exception;

use App::Kit;

diag("Testing string() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

is( $app->string->portable_crlf, "\015\012", 'portable_crlf() returns \015\012' );

my $zbt = $app->string->zero_but_true;
is( $zbt, "0E0", 'zero_but_true() returns 0E0' );
cmp_ok( $zbt, '==', 0, 'zero_but_true() is zero in numeric context' );
ok( $zbt, "zero_but_true() is true" );

ok( !exists $INC{'String/UnicodeUTF8.pm'}, 'lazy under pinning not loaded before' );
is( $app->string->bytes_size("I ♥ perl"), "10", "bytes_size() correct" );
ok( exists $INC{'String/UnicodeUTF8.pm'}, 'lazy under pinning loaded after' );
is( $app->string->char_count("I ♥ perl"), "8", "char_count() correct" );

is( $app->string->prefix, "appkit", 'prefix() default' );
throws_ok { $app->string->prefix('') } qr{prefix must be at least 1 character},             'prefix() too short';
throws_ok { $app->string->prefix('sevenly') } qr{prefix can not be more than 6 characters}, 'prefix() too long';
throws_ok { $app->string->prefix('../etc') } qr{prefix can only contain A\-Z and 0\-9},     'prefix() invalid char';
is( $app->string->prefix('new'), 'new', 'prefix setting returns prefix' );
is( $app->string->prefix,        'new', 'prefix setting retained' );

done_testing;
