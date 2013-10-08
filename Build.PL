use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::Kit',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/App/Kit.pm',
    requires          => {
        'Test::More' => 0,
    },
    add_to_cleanup => ['App-Kit-*'],
);

$builder->create_build_script();
