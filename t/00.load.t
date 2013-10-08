use Test::More;

# do these no()'s to ensure they are off before testing App::Kit’s behavior regarding them
no strict;      ## no critic
no warnings;    ## no critic

use App::Kit;
ok( defined &try,     'try is there w/out -no-try' );
ok( defined &catch,   'catch is there w/out -no-try' );
ok( defined &finally, 'finally is there w/out -no-try' );

eval 'print $x;';
like( $@, qr/Global symbol "\$x" requires explicit package name/, 'strict enabled' );
{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn = join( '', @_ );
    };
    eval 'print @X[0]';
    like( $warn, qr/Scalar value \@x\[0\] better written as \$x\[0\]/i, 'warnings enabled' );
}

use Capture::Tiny;
diag("Testing App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();
my $appt = App::Kit->new( 'test' => 1 );

TODO: {
    local $TODO = "rt 89239 needs addressed for this to work";
    is( App::Kit->new(), $app, "new() is multiton - no args" );
}

isnt( $app, $appt, "new() is multiton - diff args" );

TODO: {
    local $TODO = "rt 89239 needs addressed for this to work";
    is( $appt, App::Kit->new( 'test' => 1 ), "new() is multiton - same args via hash" );
    is( $appt, App::Kit->new( { 'test' => 1 } ), "new() is multiton - same args via hashref" );
}

my %roles = (
    'Log'    => { isa => 'Log::Dispatch' },
    'Locale' => { isa => 'Locale::Maketext::Utils::Mock::en' },
    'HTTP'   => { isa => 'HTTP::Tiny' },
    'NS'     => { isa => 'App::Kit::Facade::NS' },
    'FS'     => { isa => 'App::Kit::Facade::FS' },
    'Str'    => { isa => 'App::Kit::Facade::Str' },
    'CType'  => { isa => 'App::Kit::Facade::CType' },
    'Detect' => { isa => 'App::Kit::Facade::Detect' },
);

for my $role ( sort { $a eq 'Log' ? $b cmp $a : $a cmp $b } keys %roles ) {
    my $has = lc($role);
    ok( !exists $app->{$has}, "'$has' does not exist before it is called" );
    is( ref $app->$has(), $roles{$role}->{'isa'}, "'$has' returns the expected object" );
    ok( exists $app->{$has}, "'$has' exists after it is called" );
}

done_testing;
