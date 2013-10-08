use Test::More;
use Test::Exception;
use Class::Unload;

use App::Kit;

diag("Testing fsutil() App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

is( $app, $app->fsutil->_app, '_app() returns instantiation app' );

# $app->fsutil->cwd
ok( !exists $INC{'Cwd.pm'}, 'Sanity: Cwd not loaded before cwd()' );
is( $app->fsutil->cwd, Cwd::cwd(), 'cwd() meth returns same Cwd::cwd' );    # since the method loads the module the second arg works without an explicit use statement
ok( exists $INC{'Cwd.pm'}, 'Cwd lazy loaded on initial cwd()' );

# $app->fsutil->spec
Class::Unload->unload('File::Spec');                                        # Class::Unload brings File::Spec in
ok( !exists $INC{'File/Spec.pm'}, 'Sanity: File::Spec not loaded before spec()' );
is( $app->fsutil->spec, 'File::Spec', 'spec returns class name for method calls' );
ok( exists $INC{'File/Spec.pm'}, 'File::Spec lazy loaded on initial spec()' );

# $app->fsutil->bindir
Class::Unload->unload('FindBin');
ok( !exists $INC{'FindBin.pm'}, 'Sanity: Findbin not loaded before bindir()' );
is( $app->fsutil->bindir, $FindBin::Bin, 'bindir() returns $Findbin::Bin first' );
ok( exists $INC{'FindBin.pm'}, 'Findbin lazy loaded on initial bindir()' );
{
    local $FindBin::Bin = undef;
    no warnings 'redefine';
    local *FindBin::again = sub { return "foo" };

    delete $app->fsutil->{bindir};
    is( $app->fsutil->bindir, 'foo', 'bindir() returns FindBin->again second' );

    *FindBin::again = sub { return };
    delete $app->fsutil->{bindir};
    is( $app->fsutil->bindir, $app->fsutil->cwd, 'bindir() returns cwd third' );
}
is( $app->fsutil->bindir("mybin"), 'mybin', 'bindir() sets and returns manually set value' );
is( $app->fsutil->bindir,          'mybin', 'bindir() returns manually set value' );

# $app->fsutil->tmpdir
ok( !exists $INC{'File/Temp.pm'}, 'Sanity: File::Temp not loaded before tmpdir()' );
my $dir = $app->fsutil->tmpdir;
ok( -d $dir,                     'tmpdir() returns file name' );
ok( exists $INC{'File/Temp.pm'}, 'File::Temp lazy loaded on initial tmpdir()' );

# $app->fsutil->tmpfile
Class::Unload->unload('File::Temp');
ok( !exists $INC{'File/Temp.pm'}, 'Sanity: File::Temp not loaded before tmpfile()' );
my $file;
{    # hack to silence warnings due to Class::Unload not being able to fully do some things (see rt 88888)
    local $SIG{__WARN__} = sub { 1 };
    $file = $app->fsutil->tmpfile;
}
ok( -f $file,                    'tmpfile() returns file name' );
ok( exists $INC{'File/Temp.pm'}, 'File::Temp lazy loaded on initial tmpfile()' );

# ########################
# #### File::Path::Tiny ##
# ########################

my $fpt_dir = $app->fsutil->tmpdir;
my $mk_me = $app->fsutil->spec->catdir( $fpt_dir, qw(foo bar baz wop) );

# $app->fsutil->mkpath
ok( !exists $INC{'File/Path/Tiny.pm'}, 'Sanity: File::Path::Tiny  not loaded before mkpath()' );
ok $app->fsutil->mkpath($mk_me), 'mkpath() returns true';
ok -d $mk_me, 'mkpath() creates path';
ok( exists $INC{'File/Path/Tiny.pm'}, 'File::Path::Tiny lazy loaded on initial mkpath()' );

# $app->fsutil->rmpath
Class::Unload->unload('File::Path::Tiny');
ok( !exists $INC{'File/Path/Tiny.pm'}, 'Sanity: File::Path::Tiny not loaded before rmpath()' );
ok $app->fsutil->rmpath($mk_me), 'rmpath() returns true';
ok !-d $mk_me, 'rmpath() removes path';
ok( exists $INC{'File/Path/Tiny.pm'}, 'File::Path::Tiny lazy loaded on initial rmpath()' );

# $app->fsutil->empty_dir
Class::Unload->unload('File::Path::Tiny');
ok( !exists $INC{'File/Path/Tiny.pm'}, 'Sanity: File::Path::Tiny not loaded before empty_dir()' );
ok $app->fsutil->empty_dir($fpt_dir), 'empty_dir() rereturns true';
ok -d $fpt_dir, 'empty_dir() does not remove given dir';
opendir my $dh, $fpt_dir || die "Could not open “$fpt_dir”: $!";
my @con = grep { !m/^..?$/ } readdir($dh);
close $dh;
is_deeply \@con, [], 'empty_dir() empties dir';
ok( exists $INC{'File/Path/Tiny.pm'}, 'File::Path::Tiny lazy loaded on initial empty_dir()' );

# $app->fsutil->mk_parent
my $fpt_prnt = $app->fsutil->spec->catdir( $fpt_dir, "jibby" );
my $fpt_file = $app->fsutil->spec->catfile( $fpt_dir, "jibby", "wonka" );

Class::Unload->unload('File::Path::Tiny');
ok( !exists $INC{'File/Path/Tiny.pm'}, 'Sanity: File::Path::Tiny not loaded before mk_parent()' );
ok $app->fsutil->mk_parent($fpt_file), 'mk_parent() returns true';
ok -d $fpt_prnt,  "mk_parent() creates path's parent";
ok !-e $fpt_file, "mk_parent() does not create path";
ok( exists $INC{'File/Path/Tiny.pm'}, 'File::Path::Tiny lazy loaded on initial mk_parent()' );

ok( !exists $INC{'Path/Iter.pm'}, 'Sanity: Path::Iter not loaded before get_iterator()' );

my $iter = $app->fsutil->get_iterator($fpt_dir);
is( ref($iter), 'CODE', 'get_iterator() returns code ref' );
my @list;
while ( my $p = $iter->() ) {
    push @list, $p;
}
is_deeply( [ sort @list ], [ $fpt_dir, $fpt_prnt ], 'iterator returns expected' );
ok( exists $INC{'Path/Iter.pm'}, 'Path::Iter lazy loaded on initial get_iterator()' );

# ###################
# #### File::Slurp ##
# ###################

my $fsdir = $app->fsutil->tmpdir;
my $fsfile = $app->fsutil->spec->catfile( $fsdir, 'foo' );

# $app->fsutil->read_dir
Class::Unload->unload('File::Slurp');
ok( !exists $INC{'File/Slurp.pm'}, 'Sanity: File::Slurp not loaded before read_dir()' );
is_deeply [ $app->fsutil->read_dir($fsdir) ], [], 'read_dir() on empty dir';
ok( exists $INC{'File/Slurp.pm'}, 'File::Slurp lazy loaded on initial read_dir()' );

# $app->fsutil->write_file
Class::Unload->unload('File::Slurp');
ok( !exists $INC{'File/Slurp.pm'}, 'Sanity: File::Slurp not loaded before write_file()' );
ok $app->fsutil->write_file( $fsfile, "foo\nbar\n" ), 'write_file() returns true on success';
ok( exists $INC{'File/Slurp.pm'}, 'File::Slurp lazy loaded on initial write_file()' );
dies_ok { $app->fsutil->write_file( $fsdir, "foo\n" ) } 'write_file() failure is fatal';

# $app->fsutil->read_file
Class::Unload->unload('File::Slurp');
ok( !exists $INC{'File/Slurp.pm'}, 'Sanity: File::Slurp not loaded before read_file()' );
is_deeply [ $app->fsutil->read_file($fsfile) ], [ "foo\n", "bar\n" ], 'read_file() in array context';
ok( exists $INC{'File/Slurp.pm'}, 'File::Slurp lazy loaded on initial read_file()' );
is $app->fsutil->read_file($fsfile), "foo\nbar\n", 'read_file() in scalar context';
dies_ok { $app->fsutil->read_file($fsdir) } 'read_file() failure is fatal';

# more $app->fsutil->read_dir
is_deeply [ $app->fsutil->read_dir($fsdir) ], ['foo'], 'read_dir() on dir w/ files';
dies_ok { $app->fsutil->read_dir('no-exist') } 'read_dir() failure is fatal';

#############################
#### File::Copy::Recursive ##
#############################

# TODO use (forth coming AOTW) modern version

#################################
#### TODO: $app->fsutil->file_lookup ## Sprtin tailstails
#################################

my $tmp = $app->fsutil->tmpdir;
$app->fsutil->bindir($tmp);
my $main_dir = $app->fsutil->spec->catdir( $tmp, '.appkit.d' );

is_deeply( [ $app->fsutil->file_lookup ], [$main_dir], 'file_lookup(): no args gives inc dirs' );
is_deeply( [ $app->fsutil->file_lookup('fiddle.conf') ], [ $app->fsutil->spec->catfile( $main_dir, 'fiddle.conf' ) ], 'file_lookup(): one arg is file name' );
is_deeply( [ $app->fsutil->file_lookup( 'config', 'fiddle.conf' ) ], [ $app->fsutil->spec->catfile( $main_dir, 'config', 'fiddle.conf' ) ], 'file_lookup(): multi arg is paths parts' );

# { inc => […], }
is_deeply( [ $app->fsutil->file_lookup( { inc => [ 'myhack', 'yourhack' ], } ) ], [ 'myhack', 'yourhack', $main_dir ], 'file_lookup(): inc hash, no args gives inc dirs' );
is_deeply(
    [ $app->fsutil->file_lookup( 'fiddle.conf', { inc => [ 'myhack', 'yourhack' ], } ) ],
    [
        $app->fsutil->spec->catfile( 'myhack',   'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'yourhack', 'fiddle.conf' ),
        $app->fsutil->spec->catfile( $main_dir,  'fiddle.conf' ),
    ],
    'file_lookup(): inc hash,one arg is file name'
);
is_deeply(
    [ $app->fsutil->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', 'yourhack' ], } ) ],
    [
        $app->fsutil->spec->catfile( 'myhack',   'config', 'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'yourhack', 'config', 'fiddle.conf' ),
        $app->fsutil->spec->catfile( $main_dir,  'config', 'fiddle.conf' ),
    ],
    'file_lookup(): inc hash,multi arg is paths parts'
);

# fsutil->inc([…])
$app->fsutil->inc( [ 'foo', 'bar' ] );
is_deeply( [ $app->fsutil->file_lookup ], [ $main_dir, 'foo', 'bar' ], 'file_lookup(): inc(), no args gives inc dirs' );
is_deeply(
    [ $app->fsutil->file_lookup('fiddle.conf') ],
    [
        $app->fsutil->spec->catfile( $main_dir, 'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'foo',     'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'bar',     'fiddle.conf' ),
    ],
    'file_lookup(): inc(), one arg is file name'
);
is_deeply(
    [ $app->fsutil->file_lookup( 'config', 'fiddle.conf' ) ],
    [
        $app->fsutil->spec->catfile( $main_dir, 'config', 'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'foo',     'config', 'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'bar',     'config', 'fiddle.conf' ),
    ],
    'file_lookup(): inc(), multi arg is paths parts'
);

# { inc => […], } and  fsutils->inc([…])
is_deeply( [ $app->fsutil->file_lookup( { inc => [ 'myhack', 'yourhack' ], } ) ], [ 'myhack', 'yourhack', $main_dir, 'foo', 'bar' ], 'file_lookup(): inc() and inc hash, no args gives inc dirs' );
is_deeply(
    [ $app->fsutil->file_lookup( 'fiddle.conf', { inc => [ 'myhack', 'yourhack' ], } ) ],
    [
        $app->fsutil->spec->catfile( 'myhack',   'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'yourhack', 'fiddle.conf' ),
        $app->fsutil->spec->catfile( $main_dir,  'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'foo',      'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'bar',      'fiddle.conf' ),
    ],
    'file_lookup(): inc() and inc hash, one arg is file name'
);
is_deeply(
    [ $app->fsutil->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', 'yourhack' ], } ) ],
    [
        $app->fsutil->spec->catfile( 'myhack',   'config', 'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'yourhack', 'config', 'fiddle.conf' ),
        $app->fsutil->spec->catfile( $main_dir,  'config', 'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'foo',      'config', 'fiddle.conf' ),
        $app->fsutil->spec->catfile( 'bar',      'config', 'fiddle.conf' ),
    ],
    'file_lookup(): inc() and inc hash, multi arg is paths parts'
);

# scalar context:

my $hack_dir = $app->fsutil->spec->catdir( $tmp, 'yourhack' );
my $foo_dir  = $app->fsutil->spec->catdir( $tmp, 'foo' );

my $hack_dir_c = $app->fsutil->spec->catdir( $hack_dir, 'config' );
my $cnfg_dir_c = $app->fsutil->spec->catdir( $main_dir, 'config' );
my $foo_dir_c  = $app->fsutil->spec->catdir( $foo_dir,  'config' );
$app->fsutil->mkpath($hack_dir_c) || die "Could not mkpath “$hack_dir_c”: $!";
$app->fsutil->mkpath($cnfg_dir_c) || die "Could not mkpath “$cnfg_dir_c”: $!";
$app->fsutil->mkpath($foo_dir_c)  || die "Could not mkpath “$foo_dir_c”: $!";
$app->fsutil->inc( [ $foo_dir, 'bar' ] );

$file = $app->fsutil->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', $hack_dir ], } );
is( $file, undef, 'file_lookup() in scalar returns nothing when the path does not exist' );

$app->fsutil->write_file( $app->fsutil->spec->catfile( $foo_dir_c, 'fiddle.conf' ), '' );
$file = $app->fsutil->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', $hack_dir ], } );
is( $file, undef, 'file_lookup() in scalar returns nothing when the path does exist but is empty' );

$app->fsutil->write_file( $app->fsutil->spec->catfile( $foo_dir_c, 'fiddle.conf' ), 'howdy' );
$file = $app->fsutil->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', $hack_dir ], } );
is( $file, $app->fsutil->spec->catfile( $foo_dir_c, 'fiddle.conf' ), 'file_lookup() in scalar returns path when the path does exist and is not empty (inc)' );

$app->fsutil->write_file( $app->fsutil->spec->catfile( $cnfg_dir_c, 'fiddle.conf' ), 'howdy' );
$file = $app->fsutil->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', $hack_dir ], } );
is( $file, $app->fsutil->spec->catfile( $cnfg_dir_c, 'fiddle.conf' ), 'file_lookup() in scalar returns first file found (prefix dir)' );

$app->fsutil->write_file( $app->fsutil->spec->catfile( $hack_dir_c, 'fiddle.conf' ), 'howdy' );
$file = $app->fsutil->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', $hack_dir ], } );
is( $file, $app->fsutil->spec->catfile( $hack_dir_c, 'fiddle.conf' ), 'file_lookup() in scalar returns first file found inc arg (inc arg)' );

done_testing;
