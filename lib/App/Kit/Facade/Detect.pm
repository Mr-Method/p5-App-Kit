package App::Kit::Facade::Detect;

## no critic (RequireUseStrict) - Moo does strict
use Moo;

Sub::Defer::defer_sub __PACKAGE__ . '::is_web' => sub {
    require Web::Detect;
    return sub {
        return 1 if Web::Detect::detect_web_fast();
        return;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::is_interactive' => sub {
    require IO::Interactive::Tiny;
    return sub {
        shift;
        goto &IO::Interactive::Tiny::is_interactive;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::has_net' => sub {
    require Net::Detect;
    return sub {
        shift;
        goto &Net::Detect::detect_net;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::is_testing' => sub {
    require Test::Detect;
    return sub {
        return 1 if Test::Detect::detect_testing();
        return;
    };
};

1;
