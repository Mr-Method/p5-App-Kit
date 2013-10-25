package App::Kit::Obj::NS;

## no critic (RequireUseStrict) - Moo does strict/warnings
use Moo;

our $VERSION = '0.1';

has base => (
    is       => 'rw',
    required => 1,
    isa      => sub {
        require Module::Want;
        die "'base' must ne a valid namespace or object\n" unless Module::Want::is_ns( $_[0] ) || Module::Want::is_ns( ref $_[0] );
    },
);

############################
#### 'base' attr fiddling ##
############################

# $app->ns->employ('Some::Role', …) and, FWIW, App->ns->employ('Some::Role)
Sub::Defer::defer_sub __PACKAGE__ . '::employ' => sub {
    require Role::Tiny;
    return sub {
        my $self = shift;
        my $meth = ref( $self->base ) ? 'apply_roles_to_object' : 'apply_roles_to_package';
        return Role::Tiny->$meth( $self->base, @_ );
    };
};

# $app->ns->absorb("Foo::Bar:zong", …); $app->zong (and, FWIW, App->zong)
sub absorb {
    my $self = shift;
    no strict 'refs';    ## no critic
    for my $full_ns (@_) {
        my $base = ref( $self->base ) || $self->base;
        my $func = $self->normalize_ns($full_ns);    # or ??

        if ( $func =~ m/(.+)::([^:]+)$/ ) {
            my $ns = $1;
            $func = $2;
            $self->have_mod($ns);    # or ???
        }

        *{ $base . '::' . $func } = sub {
            shift;
            goto &{$full_ns};
        };
    }
}

#######################
#### caller fiddling ##
#######################

# $app->ns->impose('pragma', 'Mod::Ule', ['foo::bar',1,2,3]);
# maybe if pragmas could happen, otherwise re-think
# Sub::Defer::defer_sub __PACKAGE__ . '::impose' => sub {
#     require Import::Into;
#     return sub {
#         my $self = shift;
#         my $caller = caller(1) || caller(0);
#
#         for my $class ( @_ ? @_ : qw(strict warnings Try::Tiny Carp) ) {
#             my ( $ns, @import_args ) = ref($class) ? @{$class} : ($class);
#
#             # ?? if !$self->is_ns($ns);
#             $self->have_mod($ns);    # or ???
#
#             if (@import_args) {
#                 $ns->import::into( $caller, @import_args );
#             }
#             else {
#                 # use Devel::Kit::TAP;
#                 # d("$ns->import::into($caller);");
#                 $ns->import::into($caller);
#             }
#         }
#     };
# };

# $app->ns->enable('Foo::Bar::zing', …) # zing() from Foo::Bar
sub enable {
    my $self = shift;
    my $caller = caller(1) || caller(0);

    no strict 'refs';    ## no critic
    for my $full_ns (@_) {

        # ?? if !$self->is_ns($full_ns);
        my $func = $self->normalize_ns($full_ns);

        if ( $func =~ m/(.+)::([^:]+)$/ ) {
            my $ns = $1;
            $func = $2;
            $self->have_mod($ns);    # or ???
        }

        *{ $caller . '::' . $func } = \&{$full_ns};
    }
}

##########################
#### NS utility methods ##
##########################

Sub::Defer::defer_sub __PACKAGE__ . '::is_ns' => sub {
    require Module::Want;
    return sub {
        shift;
        goto &Module::Want::is_ns;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::normalize_ns' => sub {
    require Module::Want;
    return sub {
        shift;
        goto &Module::Want::normalize_ns;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::have_mod' => sub {
    require Module::Want;
    return sub {
        shift;
        goto &Module::Want::have_mod;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::ns2distname' => sub {
    require Module::Want;
    return sub {
        shift;
        goto &Module::Want::ns2distname;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::distname2ns' => sub {
    require Module::Want;
    return sub {
        shift;
        goto &Module::Want::distname2ns;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::sharedir' => sub {
    require File::ShareDir;
    return sub {
        my ( $self, $ns_or_dist ) = @_;    # ? optionally $self->have_mod($ns), seems like a bad idea … ?

        if ( $self->is_ns($ns_or_dist) ) {
            $ns_or_dist = $self->ns2distname($ns_or_dist);    # turn it into a dist
        }
        elsif ( !$self->is_ns( $self->distname2ns($ns_or_dist) ) ) {
            return;                                           # not a valid dist
        }

        return eval { File::ShareDir::dist_dir($ns_or_dist) };
    };
};

1;

__END__

=encoding utf-8

=head1 NAME

App::Kit::Obj::FIX - FIX utility object

=head1 VERSION

This document describes App::Kit::Obj::FIX version 0.1

=head1 SYNOPSIS

    my $FIX = App::Kit::Obj::FIX->new();
    $FIX->fix()->…

=head1 DESCRIPTION

FIX utility object

=head1 INTERFACE

=head2 new()

Returns the object, takes no arguments.

=head2 FIX()

FIX

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<FIX>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

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
