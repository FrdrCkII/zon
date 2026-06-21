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
  name = "checks";
  file = ./checks.nix;
  option = mkOption {
    type = lazyAttrsOf package;
    default = { };
    description = ''
      Derivations to be built by [`nix flake check`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-check.html).
    '';
  };
}
