package Testlib::Collectord;

use strict;
use warnings;

use Exporter qw(import);
use POSIX qw(WNOHANG);
use Socket qw(MSG_NOSIGNAL getaddrinfo);
use Testlib::Retry qw(retry);

our @EXPORT_OK = qw(
    start
    isRunning

    connect
    disconnect

    sendEvent
);

################################################################################
# Process control

my @pids;
END { kill('TERM', $_) for @pids }

sub start
{
    use autodie qw(:default exec);
    my ($path) = @_;
    exec($path) unless my $pid = fork();
    push(@pids, $pid);
    $pid;
}

sub isRunning
{
    use autodie;
    my ($pid) = @_;
    my $waitpid = waitpid($pid, WNOHANG);
    $waitpid == 0;
}

################################################################################
# Socket control

sub connect
{
    use autodie;
    my ($err, $addrinfo) = getaddrinfo('127.0.0.1', 1324);
    my ($family, $socktype, $protocol, $addr) =
        $addrinfo->@{'family', 'socktype', 'protocol', 'addr'};
    socket(my $socket, $family, $socktype, $protocol);
    retry(sub { connect($socket, $addr) },
          sub { $_[0] < 5 && $@ =~ /Connection refused/ });
    $socket;
}

sub disconnect
{
    use autodie;
    my ($socket) = @_;
    close($socket);
}

################################################################################
# Sending messages

sub sendEvent
{
    use autodie;
    my ($socket, %event) = @_;
    my $message = pack(
        'dva*va*',
        $event{metric},
        length($event{class}),   $event{class},
        length($event{payload}), $event{payload},
    );
    send($socket, $message, MSG_NOSIGNAL);
}

1;
