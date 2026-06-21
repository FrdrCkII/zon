{
  lib,
  falake,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    getExe
    ;
  inherit (types)
    lazyAttrsOf
    coercedTo
    package
    submodule
    enum
    str
    raw
    ;
  inherit (falake)
    mkTransposedPerSystemModule
    ;

  programType = coercedTo derivationType getExe str;

  derivationType = package // {
    check = lib.isDerivation;
  };

  appType = submodule {
    options = {
      type = mkOption {
        type = enum [ "app" ];
        default = "app";
        description = ''
          A type tag for `apps` consumers.
        '';
      };
      program = mkOption {
        type = programType;
        description = ''
          A path to an executable or a derivation with `meta.mainProgram`.
        '';
      };
      meta = mkOption {
        type = lazyAttrsOf raw;
        default = { };
        # TODO refer to Nix manual 2.25
        description = ''
          Metadata information about the app.
          Standardized in Nix at <https://github.com/NixOS/nix/pull/11297>.

          Note: `nix flake check` is only aware of the `description` attribute in `meta`.
        '';
      };
    };
  };
in
mkTransposedPerSystemModule {
  name = "apps";
  file = ./apps.nix;
  option = mkOption {
    type = lazyAttrsOf appType;
    default = { };
    description = ''
      Programs runnable with nix run `<name>`.
    '';
    example = lib.literalExpression or lib.literalExample ''
      {
        default.program = "''${config.packages.hello}/bin/hello";
      }
    '';
  };
}
