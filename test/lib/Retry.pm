package Testlib::Retry;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT = qw(retry);

=head2 retry(\&block, \&condition)

Retry the block until the condition returns false. The condition may access
the following three variables to decide whether to retry:

=over

=item C<$_>

The return value of the block, or undef if it did not return.

=item C<$@>

The exception thrown by the block, or the empty string if it did not throw.

=item C<$_[0]>

The number of retries that happened before in this invocation of retry.

=back

=cut

sub retry
{
    my ($block, $condition) = @_;
    for (my $i = 0; ; ++$i) {
        local $_ = eval { $block->() };
        my    $e = $@;
        next if $condition->($i);
        return $_ if $e eq '';
        die $e;
    }
}

=head1 BUGS

The retry subroutine always invokes the block in scalar context. If this is
undesired, the caller can wrap the return value in an array reference in the
block and unwrap it after retry returns.

=cut
