{ pkgs, ... }: {
  config = {
    environment = {
      systemPackages = [
        pkgs.coreutils-full
        pkgs.findutils
        pkgs.diffutils
        pkgs.gnused
        pkgs.gnugrep
        pkgs.gawk
        pkgs.gnumake
        pkgs.just
        pkgs.binutils
        pkgs.gcc
        pkgs.pkg-config
        pkgs.cmake
        pkgs.git
        pkgs.yazi
        pkgs.wget
        pkgs.curl
        pkgs.treefmt
        pkgs.alejandra
        pkgs.nixfmt
        pkgs.jq
      ];
    };
  };
}
