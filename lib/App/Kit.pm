package App::Kit;

## no critic (RequireUseStrict) - Moo does strict and warnings
use Moo;

our $VERSION = '0.1';

sub import {
    strict->import;
    warnings->import;
    unless ( defined $_[1] && $_[1] eq '-no-try' ) {    # Yoda was right: there *is* -no-try!
        require Try::Tiny;

        # Try::Tiny->import();  # not like pragma in import, so:
        require Import::Into;
        my $caller = caller();
        Try::Tiny->import::into($caller);
    }
}

# tidyoff
with 'Role::Multiton', # Would like to do ::New but that falls apart once you decide to extend() See rt 89239. For now we TODO the multiton-via-new tests
    'App::Kit::Role::Log',
    'App::Kit::Role::Locale',
    'App::Kit::Role::HTTP',
    'App::Kit::Role::NS',
    'App::Kit::Role::FS',
    'App::Kit::Role::Str',
    'App::Kit::Role::CType',
    'App::Kit::Role::Detect';
# tidyon

1;

# TODO: manifest and deps

__END__

=encoding utf-8

=head1 NAME

App::Kit - A Lazy Façade to simplify your code/life

=head1 VERSION

This document describes App::Kit version 0.1

=head1 SYNOPSIS

Use directly in your code:

    ## no critic (RequireUseStrict) - App::Kit does strict and warnings
    use App::Kit;
    my $app = App::Kit->multiton; # now your script and all the modules that make it up have access to the same logging, localization, and a host of other fetaures without loading anything for them and not requiring special voo doo to load/initialize.

Or roll your own to use instead:

    package My::App;
    use Moo;
    extends 'App::Kit';
    with '…'; # add a new role
    has 'newthing' => ( … ); # add a new attr
    has '+app_kit_thingy' => ( … ); # customize an existing role/attr/method
    sub newmeth { … } # ad a new methos

=head1 DESCRIPTION

TODO: fix DESCRIPTION

TODO: document new()/multiton()

    A Lazy Façade to simplify your code/life.

Ever see this sort of thing in a growing code base:

    package My::Thing;
    
    use strict;
    use warnings;
    
    use My::Logger;
    my $logger;
    
    sub foo {
        my ($x, $y, $z) = @_;
        if ($x) {
            $logger ||= MyLogger->new;
            $logger->info("X is truly $x");
        }
        …
    }

but if that module had access to your App::Kit object:

    package My::Thing;

    ## no critic (RequireUseStrict) - App::Kit does strict and warnings
    use MyApp;
    my $app = MyApp->multiton; # ok to do this here because it is really really cheap

    sub foo {
        my ($x, $y, $z) = @_;
        if ($x) {
            $app->log->info("X is truly $x");
        }
        …
    }

=head2 only what you need, when you need it

=head2 use default objects or set your own

=head2 easy mocking (for your tests!)

TODO: read/write obj? give example

=head1 INTERFACE 

=head2 auto imports

=head3 strict and warnings enabled automatically

=head3 try/catch/finally imported automatically (unless you say not to)

L<Try::Tiny> is enabled automatically unless you pass import() “-no-try” flag (Yoda was right: there *is* -no-try!):

    use App::Kit '-no-try';

same goes for your App::Kit based object:

    use My::App '-no-try';

=head2 constructors: multiton support

=head3 new()

Since the idea of this class is to share the objects it makes more sence to use multiton() in your code.

Returns a new object everytime. Takes no arguments currently.

I'd like to make it a multiton but L<Role::Multiton::New> does not work right due to rt89239.

=head3 multiton()

Returns the same object on subsequent calls using the same arguments. Since, there are currently no argments it is essentially a singleton.

See L<Role::Multiton> for more details.

=head3 instance()

Alias to multiton(). If you ever plan on modifying the constructor to another type (weirdo) you may want to use this in your code instead of multiton().

See L<Role::Multiton> for more details.

=head2 Lazy façade methods

Each method returns a lazy loaded/instantiated object that implements the actual functionality.

=head3 $app->log

Lazy façade to a logging object via L<App::Kit::Role::Log>.

=head3 $app->locale

Lazy façade to a maketext() object via L<App::Kit::Role::Locale>. 

Has all the methods any L<Locale::Maketext::Utils> based object would have.

Localize your code now without needing an entire subsystem in place just yet!

=head3 $app->detect

Lazy façade to a context detection object via L<App::Kit::Role::Detect>.

=head3 $app->ctype

Lazy façade to ctype utility object via L<App::Kit::Role::CType>.

=head3 $app->str

Lazy façade to a srting utility object via L<App::Kit::Role::Str>.

=head3 $app->ns

Lazy façade to a name space utility object via L<App::Kit::Role::NS>.

=head3 $app->http

Lazy façade to an http client object via L<App::Kit::Role::HTTP>.

=head3 $app->fs

Lazy façade to an file system utility client object via L<App::Kit::Role::FS>.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

All errors or warnings would come from perl, L<Moo>, or the façade object in question.

=head1 CONFIGURATION AND ENVIRONMENT

App::Kit requires no configuration files or environment variables.

If, however, the façade object in question does it will be documented specifically under it.

=head1 DEPENDENCIES

L<Moo> et al.

If you don't pass in -no-try: L<Try::Tiny>  and L<Import::Into>

Other modules would be documented above under each façade object that brings them in.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

=over 4

=item 1. More Lazy façade methods

=over 4 

=item * App::Kit::Role::DB 

    # $app->db->dbh (connect() per config file || args, set UTF-8, set UTC,reconnect etc);

=item * App::Kit::Role::Runner 

    # $app->runner->commentary([], []), $app->runner->whereis(), $app->runner->syscmd() $app->runner->spork() $app->runner->as_user() $app->runner->usleep() (select(undef, undef undef, abs($n)))

=item * App::Kit::Role::Crypt 

    # $app->crypt->encrypt($str, $cipher) $app->xcrypt->decrypt($str, $cipher) ->rand_data

=item * App::Kit::Role::Cache

    # e.g Chi if it becomes drops a few pound by eating less Moose

=item * App::Kit::Role::In

    # i.e. HTTP or ARGV == $app->in->param('name')

=item * App::Kit::Role::Out

    # e.g.TT/classes/ANSI

=back

=item 2. Encapsulate tests that commonly do:

    Class::Unload->unload('…');
    ok(!exists $INC{'….pm'}, 'Sanity: … not loaded before');
    is $app->?->…, '…', '?() …'
    ok(exists $INC{'….pm'}, '… lazy loaded on initial ?()');

=item 3. easy to implement modes

for example:

=over 4

=item * root_safe: make certain methods die if called by root under some circumstance

(e.g. root calling file system utilities on paths owned by a user, forces them to drop privileges)

=item * owner_mode: process is running as owner of script

=item * chdir_safe: make chdir fatal

=back

=item 4. local()-type stash to get/set/has/del arbitrary data/objects to share w/ the rest of the consumers

=back

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
