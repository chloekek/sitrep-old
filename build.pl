=head1 NAME

Snowflake rules.

=head1 SYNOPSIS

    $ nix run -ic snowflake build.pl

=head1 DESCRIPTION

This file defines rules for the Snowflake build system. See the Snowflake
documentation for how to define rules and artifacts.

=cut

use strict;
use warnings;

use File::Basename qw(basename);
use Snowflake::Rule::Util qw(bash_strict);
use Snowflake::Rule;

################################################################################
# sitrepd

=head2 goPackage(name => $, sources => \@, dependencies => \@)

Build a Go package. The name must be the name of the package. The source must
be a Go source file. The dependencies must be other such rules.

=cut

sub goPackage
{
    my %options = @_;
    my $name         = $options{name};
    my @sources      = $options{sources}->@*;
    my @dependencies = $options{dependencies}->@*;
    my %sources_mapping = map { basename($_) => ['on_disk', $_] } @sources;
    Snowflake::Rule->new(
        name         => "Go package ‘$name’",
        dependencies => [@dependencies],
        sources      => {
            %sources_mapping,
            'NAME'            => ['inline', $name],
            'snowflake-build' => bash_strict(<<'BASH'),
                name=$(< NAME)

                flags=()
                for dependency in "$@"; do
                    flags+=(-I "$dependency")
                done

                go tool compile "${flags[@]}" -pack -o "$name".a *.go

                mkdir --parents snowflake-output/sitrep
                mv NAME snowflake-output
                mv "$name".a snowflake-output/sitrep
BASH
        },
    );
}

my $wirePackage = goPackage(
    name    => 'wire',
    sources => [
        'src/wire/fundamental.go',
        'src/wire/event.go',
    ],
    dependencies => [],
);

my $sitrepCollectordPackage = goPackage(
    name    => 'main',
    sources => ['src/main/collectord.go'],
    dependencies => [$wirePackage],
);

my $sitrepCollectord = Snowflake::Rule->new(
    name         => 'sitrepCollectord',
    dependencies => [
        $sitrepCollectordPackage,
        $wirePackage,
    ],
    sources      => {
        'snowflake-build' => bash_strict(<<'BASH'),
            flags=()
            for dependency in "${@:2}"; do
                flags+=(-L "$dependency")
            done

            go tool link "${flags[@]}" -o snowflake-output "$1/sitrep/main.a"
BASH
    },
);

################################################################################
# Tests

my @tests;

=head2 perlTest(script => $, dependencies => \@)

Define a rule that runs the given Perl script file. The script receives the
outputs of the dependencies as arguments, and must produce TAP-compatible
output for consumption by the test summary rule defined below.

=cut

sub perlTest
{
    my %options = @_;
    my $script       = $options{script};
    my @dependencies = $options{dependencies}->@*;
    my $test = Snowflake::Rule->new(
        name         => "Perl test ‘$script’",
        dependencies => \@dependencies,
        sources      => {
            'NAME'      => ['inline', $script],
            'script.pl' => ['on_disk', $script],
            'Testlib'   => ['on_disk', 'test/lib'],
            'snowflake-build' => bash_strict(<<'BASH'),
                {
                    # Insert a TAP diagnostic with the name of the test, for
                    # two reasons: so that different tests always have
                    # different output hashes; and so that it is easier for
                    # humans to interpret the test summary.
                    sed 's/^/# /; a \' NAME
                    # Test rules always “succeed”; it is the test summary rule
                    # defined below that may fail. This way we can cache test
                    # failures, which is desirable.
                    PERL5LIB=$PWD:$PERL5LIB perl script.pl "$@" || true
                } >snowflake-output 2>&1
BASH
        },
    );
    push(@tests, $test);
}

perlTest(
    script       => 'test/connectDisconnect.pl',
    dependencies => [$sitrepCollectord],
);

perlTest(
    script       => 'test/connectEventDisconnect.pl',
    dependencies => [$sitrepCollectord],
);

################################################################################
# Test summary

my $testSummary = Snowflake::Rule->new(
    name => 'Test summary',
    dependencies => [@tests],
    sources => {
        'snowflake-build' => bash_strict(<<'BASH'),
            prove --verbose --exec cat "$@" \
                | tee snowflake-output
BASH
    },
);

################################################################################
# Artifacts

(
    sitrepCollectord => $sitrepCollectord,
    testSummary => $testSummary,
);
