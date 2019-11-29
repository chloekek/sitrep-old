=head1 DESCRIPTION

Connecting, sending an event, and then disconnecting should record the event
and leave the server running.

=cut

use autodie;
use strict;
use warnings;

use Test::More (tests => 2);
use Testlib::Collectord;
use Time::HiRes qw(usleep);

BEGIN { *Collectord:: = \*Testlib::Collectord::; }

my $path = shift(@ARGV);
my $pid = Collectord::start($path);

my $socket = Collectord::connect();

Collectord::sendEvent($socket, metric => 1.0, class => 'a', payload => '{}');

Collectord::disconnect($socket);
usleep(5_000);

# TODO: Assert that event is recorded.
ok(1);

ok(Collectord::isRunning($pid));
