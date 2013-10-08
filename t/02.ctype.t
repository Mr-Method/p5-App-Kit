use Test::More;

use App::Kit;

diag("Testing ctypes() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

ok( !exists $app->{'ctypes'} || !exists $app->{'ctypes'}{'mimeobj'}, 'mimeobj not set before mimeobj called' );
isa_ok( $app->ctypes->mimeobj, 'MIME::Types' );
ok( exists $app->{'ctypes'} && exists $app->{'ctypes'}{'mimeobj'}, 'mimeobj is set after mimeobj called' );
is( $app->ctypes->mimeobj, $app->{'ctypes'}{'mimeobj'}, 'mime obj cached' );

my $js_mime = $app->ctypes->mimeobj->mimeTypeOf('js')->type();
is( $app->ctypes->get_ctype_of_ext('js'),     $js_mime, 'get_ctype_of_ext() ext only' );
is( $app->ctypes->get_ctype_of_ext('.js'),    $js_mime, 'get_ctype_of_ext() ext w/ dot' );
is( $app->ctypes->get_ctype_of_ext('foo.js'), $js_mime, 'get_ctype_of_ext() ext in path' );

my @plain = $app->ctypes->mimeobj->type("text/plain")->extensions();
is_deeply(
    [ scalar $app->ctypes->get_ext_of_ctype("text/plain") ],
    [ $plain[0] ],
    'get_ctype_of_ext() returns first in scalar context'
);
is_deeply(
    [ $app->ctypes->get_ext_of_ctype("text/plain") ],
    \@plain,
    'get_ctype_of_ext() returns all in array context'
);

done_testing;
