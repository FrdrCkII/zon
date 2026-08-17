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
        pkgs.binutils
        pkgs.gcc
        pkgs.clang
        pkgs.llvm
        pkgs.lld

        pkgs.pkg-config
        pkgs.cmake
        pkgs.git
        pkgs.flex
        pkgs.bison

        pkgs.perl
        pkgs.just
        pkgs.yazi
        pkgs.wget
        pkgs.curl

        pkgs.treefmt
        pkgs.alejandra
        pkgs.nixfmt
        pkgs.jq

        pkgs.pciutils
        pkgs.usbutils
        pkgs.mesa-demos
        pkgs.vulkan-tools
        pkgs.lshw
      ];
    };
  };
}
