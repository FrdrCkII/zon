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
    nullOr
    package
    ;
  inherit (falake)
    mkTransposedPerSystemModule
    ;
in
mkTransposedPerSystemModule {
  name = "formatter";
  file = ./formatter.nix;
  option = mkOption {
    type = nullOr package;
    default = null;
    description = ''
      A package used by [`nix fmt`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-fmt.html).
    '';
  };
}
