use Test::More;
use Test::Exception;

BEGIN { $ENV{'App-Kit_RW'} = 1; }
use App::Kit;

my @roles = (
    [ 'Locale' => { isa => 'Locale::Maketext::Utils::Mock::en' } ],
    [ 'HTTP'   => { isa => 'HTTP::Tiny' } ],
    [ 'NS'     => { isa => 'App::Kit::Facade::NS' } ],
    [ 'FS'     => { isa => 'App::Kit::Facade::FS' } ],
    [ 'Str'    => { isa => 'App::Kit::Facade::Str' } ],
    [ 'CType'  => { isa => 'App::Kit::Facade::CType' } ],
    [ 'Detect' => { isa => 'App::Kit::Facade::Detect' } ],
    [ 'DB'     => { isa => 'App::Kit::Facade::DB' } ],
    [ 'Log'    => { isa => 'Log::Dispatch' } ],
);

for my $role_ar (@roles) {
    my $role    = $role_ar->[0];
    my $role_hr = $role_ar->[1];

    my $has = lc($role);
    ok( !exists $app->{$has}, "Devel-Kit_RW '$has' does not exist before it is called" );
    is( ref $app->$has(), $role_hr->{'isa'}, "Devel-Kit_RW '$has' returns the expected object" );
    ok( exists $app->{$has}, "Devel-Kit_RW '$has' exists after it is called" );

    my $org = $app->$has();
    is( ref $app->$has( bless {}, 'Foo' ), 'Foo', "Devel-Kit_RW '$has' can be set, returns new obj" );
    is( ref $app->$has(), 'Foo', "Devel-Kit_RW '$has' subsequently returns the new object" );
    $app->$has($org);
}

done_testing;
