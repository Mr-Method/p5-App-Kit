package App::Kit::Role::Logger;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

# ro-NOOP:
#   my $isa_digit = sub { die "Must be all digits!" unless $_[0] =~ m/\A[0-9]+\z/; };
#   has _logger_reload_check_time => ( is => 'rw', lazy => 1, isa => $isa_digit, default => sub { time } );    # not rwp so its easier to test
#   has _logger_reload_check_every => ( is => 'rw', lazy => 1, isa => $isa_digit, default => sub { 30 } );     # not rwp so its easier to test

has logger => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        require Log::Dispatch::Config;

        # ro-NOOP: my ($app, %new) = @_;
        my ($app) = @_;

        my $path = $app->fsutil->file_lookup( 'config', 'logger.conf' );

        if ($path) {

            # Log::Dispatch::Config->configure( $path ); # $app->logger->reload; at will

            # since we only call instance() once this would be a noop *except* the wrapper needs it via needs_reload()
            #   (we could bypass via $app->logger->{config}->needs_reload but what if the module changes? poof!)
            Log::Dispatch::Config->configure_and_watch($path);

            my $logger = Log::Dispatch::Config->instance;

            # ? TODO: optional 'before' logger per config file or $app->conf('reload_logger')
            # check mtime instead?
            # before 'logger' => sub {
            #      if (!$app->_logger_reload_check_time() || time() - $app->_logger_reload_check_time() < $app->_logger_reload_check_every() ) {
            #          $app->_logger_reload_check_time(time());
            #          $app->logger->reload if $app->logger->needs_reload;
            #      }
            # };

            return $logger;
        }

        # ro-NOOP: elsif(keys %new) {
        # ro-NOOP:     return Log::Dispatch->new(%new);
        # ro-NOOP: }

        else {
            return Log::Dispatch->new(
                outputs => [ [ "Screen", min_level => "notice", "newline" => 1 ] ],
                callbacks => sub {
                    my %info = @_;

                    my $short = $info{'level'};
                    $short = substr( $info{'level'}, 0, 5 ) eq 'emerg' ? 'M' : uc( substr( $short, 0, 1 ) );
                    $short = " ㏒\xc2\xa0$short";    # Unicode: \x{33D2} utf-8: \xe3\x8f\x92

                    # 0 debug
                    # 1 info
                    # 2 notice
                    # 3 warning (warn)
                    # 4 error (err)
                    # 5 critical (crit)
                    # 6 alert
                    # 7 emergency (emerg)

                    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
                    my $time_stamp = sprintf( "%04d-%02d-%02d\xc2\xa0%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

                    my $tap = $app->detect->is_testing ? '#' : '';    # make it TAP safe

                    # TODO: format via $app->output e.g.:
                    # return $app->output->current_indent() . $app->output->short_indent() . $app->output->class($short, $info{'level'}) . ' ' . $app->output->class($time_stamp, 'dim') . $app->output->short_indent() . $app->output->class($info{message}, 'code');
                    return "$tap  $short $time_stamp  $info{message}";
                }
            );
        }
    },
);

1;
