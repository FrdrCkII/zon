{
  lib,
  falake,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    literalExpression
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
  name = "devShells";
  file = ./devShells.nix;
  option = mkOption {
    type = lazyAttrsOf package;
    default = { };
    description = ''
      An attribute set of packages to be used as shells.
      [`nix develop .#<name>`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-develop.html) will run `devShells.<name>`.
    '';
    example = literalExpression ''
      {
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ wget bat cargo ];
        };
      }
    '';
  };
}
