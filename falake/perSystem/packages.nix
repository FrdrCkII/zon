{
  lib,
  falake,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    ;
  inherit (types)
    lazyAttrsOf
    package
    ;
  inherit (falake)
    mkTransposedPerSystemModule
    ;
in
mkTransposedPerSystemModule {
  name = "packages";
  file = ./packages.nix;
  option = mkOption {
    type = lazyAttrsOf package;
    default = { };
    description = ''
      An attribute set of packages to be built by [`nix build`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html).

      `nix build .#<name>` will build `packages.<name>`.
    '';
  };
}
