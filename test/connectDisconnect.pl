=head1 DESCRIPTION

Connecting and then disconnecting should leave the server running.

=cut

use strict;
use warnings;

use Test::More (tests => 1);
use Testlib::Collectord;
use Time::HiRes qw(usleep);

BEGIN { *Collectord:: = \*Testlib::Collectord::; }

my $path = shift(@ARGV);

my $pid = Collectord::start($path);

my $socket = Collectord::connect();
usleep(5_000);

Collectord::disconnect($socket);
usleep(5_000);

ok(Collectord::isRunning($pid));
