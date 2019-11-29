{pkgs ? import ./nix/pkgs.nix {}}:
[
    pkgs.bash
    pkgs.coreutils
    pkgs.gnused
    pkgs.go
    pkgs.perl
    pkgs.snowflake
]
