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
    raw
    ;
  inherit (falake)
    mkTransposedPerSystemModule
    ;
in
mkTransposedPerSystemModule {
  name = "legacyPackages";
  file = ./legacyPackages.nix;
  option = mkOption {
    type = lazyAttrsOf raw;
    default = { };
    description = ''
      An attribute set of unmergeable values. This is also used by [`nix build .#<attrpath>`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html).
    '';
  };
}
