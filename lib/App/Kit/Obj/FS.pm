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
