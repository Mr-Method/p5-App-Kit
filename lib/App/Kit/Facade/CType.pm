package App::Kit::Facade::CTypes;

## no critic (RequireUseStrict) - Moo does strict
use Moo;

has mimeobj => (
    'is'      => 'ro',
    'lazy'    => 1,
    'default' => sub {
        require MIME::Types;
        return MIME::Types->new();
    },
);

sub get_ctype_of_ext {
    my ( $self, $path ) = @_;
    return eval { $self->mimeobj->mimeTypeOf($path)->type() };
}

sub get_ext_of_ctype {
    my ( $self, $ctype ) = @_;
    return eval { wantarray ? $self->mimeobj->type($ctype)->extensions() : ( $self->mimeobj->type($ctype)->extensions() )[0] };
}

1;
