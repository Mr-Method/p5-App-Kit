package App::Kit::Facade::String;

## no critic (RequireUseStrict) - Moo does strict
use Moo;

sub portable_crlf {
    return "\015\012";    # "\r\n" is not portable
}

sub zero_but_true { return "0E0"; }

Sub::Defer::defer_sub __PACKAGE__ . '::bytes_size' => sub {
    require String::UnicodeUTF8;
    return sub {
        shift;
        goto &String::UnicodeUTF8::bytes_size;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::char_count' => sub {
    require String::UnicodeUTF8;
    return sub {
        shift;
        goto &String::UnicodeUTF8::char_count;
    };
};

has prefix => (
    is   => 'rw',
    lazy => 1,
    isa  => sub {
        die "prefix must be at least 1 character"      unless length( $_[0] ) > 0;
        die "prefix can only contain A-Z and 0-9"      unless $_[0] =~ m/\A[A-Za-z0-9]+\z/;
        die "prefix can not be more than 6 characters" unless length( $_[0] ) < 7;
    },
    default => sub { return 'appkit' },
);

# TODO: trim && ws_norm($str)

1;
