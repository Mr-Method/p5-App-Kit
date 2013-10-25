package App::Kit::Obj::FS;

## no critic (RequireUseStrict) - Moo does strict
use Moo;

our $VERSION = '0.1';

has _app => (
    is       => 'ro',
    required => 1,
);

# same RSS/time as redefine-self but less room for error maintaining the resulting code in 2 places (plus Sub::Defer is already loaded via Moo), so it wins!
Sub::Defer::defer_sub __PACKAGE__ . '::cwd' => sub {
    require Cwd;
    return sub { shift; goto &Cwd::cwd }
};

# TODO: sort out conf file methods (or Config::Any etc):
#   read_json
#   write_json

#### same RSS/time as redefine-self plus 3.5% more ops ##
# sub cwd {
#     require Cwd;
#     shift;
#     goto &Cwd::cwd
# }
#
# sub cwd {
#     require Cwd;
#     no warnings 'redefine';
#     *cwd = sub {
#         shift;
#         goto &Cwd::cwd
#     };
#     shift;
#     goto &Cwd::cwd
# }
#
#
#### adds .75MB to RSS and 44.6% increase in opts, ick! ##
# sub cwd { shift->_cwd_code->(@_); }
#
# has _cwd_code => (
#     'is' => 'ro',
#     'lazy' => '1',
#     'default' => sub {
#         require Cwd;
#         return sub { shift; goto &Cwd::cwd }
#     },
# );

# TODO chdri related stuff:
# Sub::Defer::defer_sub __PACKAGE__ . '::chdir' => sub {
#     require Cwd;
#     return sub {
#         my $self = shift;
#         $self->starting_dir( $self->cwd );
#         goto &Cwd::chdir;
#     };
# };
#
# sub chbak {
#     my $self  = shift;
#     my $start = $self->starting_dir();
#     return 2 if !defined $start;
#
#     $self->chdir($start) || return;
#     $self->starting_dir(undef);
#
#     return 1;
# }

sub file_lookup {
    my ( $self, @rel_parts ) = @_;

    my $call = ref( $rel_parts[-1] ) ? pop(@rel_parts) : { 'inc' => [] };
    $call->{'inc'} = [] if !exists $call->{'inc'} || ref $call->{'inc'} ne 'ARRAY';

    my @paths;
    my $name = $self->_app->str->prefix;
    for my $base ( @{ $call->{'inc'} }, $self->spec->catdir( $self->bindir(), ".$name.d" ), @{ $self->inc } ) {
        next if !$base;
        push @paths, $self->spec->catfile( $base, @rel_parts );
    }

    return @paths if wantarray;

    my $path = '';
    for my $check (@paths) {
        if ( -e $check && -s _ ) {
            $path = $check;
            last;
        }
    }

    return $path if $path;
    return;
}

# Sub::Defer::defer_sub __PACKAGE__ . '::mkfile' => sub {
#     require File::Touch;
#     return sub {
#         my ($fs, $path) = @_;
#         $fs->mk_parent( $path ) || return;
#         eval { File::Touch::touch( $path ) } || return;
#         return 1;
#     };
# };

Sub::Defer::defer_sub __PACKAGE__ . '::mkpath' => sub {
    require File::Path::Tiny;
    return sub {
        shift;
        goto &File::Path::Tiny::mk;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::rmpath' => sub {
    require File::Path::Tiny;
    return sub {
        shift;
        goto &File::Path::Tiny::rm;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::empty_dir' => sub {
    require File::Path::Tiny;
    return sub {
        shift;
        goto &File::Path::Tiny::empty_dir;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::mk_parent' => sub {
    require File::Path::Tiny;
    return sub {
        shift;
        goto &File::Path::Tiny::mk_parent;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::tmpfile' => sub {
    require File::Temp;
    return sub {
        $_[0] = 'File::Temp';    # quicker than: shift; unshift(@_, 'Class::Name::Here');
        goto &File::Temp::new;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::tmpdir' => sub {
    require File::Temp;
    return sub {
        $_[0] = 'File::Temp';    # quicker than: shift; unshift(@_, 'Class::Name::Here');
        goto &File::Temp::newdir;
    };
};

has spec => (
    'is'      => 'ro',
    'lazy'    => '1',
    'default' => sub {
        require File::Spec;
        return 'File::Spec';
    },
);

has bindir => (
    'is'      => 'rw',
    'lazy'    => '1',
    'default' => sub {
        require FindBin;
        require Cwd;
        return $FindBin::Bin || FindBin->again() || Cwd::cwd();
    },
);

has inc => (
    'is'      => 'rw',
    'default' => sub { [] },
    'isa'     => sub { die "inc must be an array ref" unless ref( $_[0] ) eq 'ARRAY' },
);

# has starting_dir => (
#     'is'      => 'rw',
#     'default' => sub { undef },
# );

Sub::Defer::defer_sub __PACKAGE__ . '::read_dir' => sub {
    require File::Slurp;
    return sub {
        shift;
        goto &File::Slurp::read_dir;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::read_file' => sub {
    require File::Slurp;
    return sub {
        shift;
        goto &File::Slurp::read_file;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::write_file' => sub {
    require File::Slurp;
    return sub {
        shift;
        goto &File::Slurp::write_file;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::get_iterator' => sub {
    require Path::Iter;
    return sub {
        shift;
        goto &Path::Iter::get_iterator;
    };
};

# TODO new FCR

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
