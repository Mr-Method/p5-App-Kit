package App::Kit::Facade::NSUtil;

## no critic (RequireUseStrict) - Moo does strict/warnings
use Moo;

$App::Kit::Facade::NSUtil::VERSION = '0.1';

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

# $app->nsutil->employ('Some::Role', …) and, FWIW, App->nsutil->employ('Some::Role)
Sub::Defer::defer_sub __PACKAGE__ . '::employ' => sub {
    require Role::Tiny;
    return sub {
        my $self = shift;
        my $meth = ref( $self->base ) ? 'apply_roles_to_object' : 'apply_roles_to_package';
        return Role::Tiny->$meth( $self->base, @_ );
    };
};

# $app->nsutil->absorb("Foo::Bar:zong", …); $app->zong (and, FWIW, App->zong)
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

# $app->nsutil->impose('pragma', 'Mod::Ule', ['foo::bar',1,2,3]);
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

# $app->nsutil->enable('Foo::Bar::zing', …) # zing() from Foo::Bar
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
