{
  name,
  topConfig,
  config,
  lib,
  ...
}:
{
  options = {
    name = lib.mkOption {
      type = lib.types.str;
      default = name;
      description = "The names used in functions like `perSystem` and `withSystem`";
    };
    localSystem = lib.mkOption {
      type = lib.types.str;
      default = config.name;
      description = "The local system for nixpkgs.";
    };
    crossSystem = lib.mkOption {
      type = with lib.types; nullOr str;
      default = config.localSystem;
      description = "The cross system for nixpkgs.";
    };
    overlays = lib.mkOption {
      type = lib.types.listOf (
        lib.mkOptionType {
          name = "nixpkgs-overlay";
          description = "nixpkgs overlay";
          check = lib.isFunction;
          merge = lib.mergeOneOption;
        }
      );
      default = [ ];
      description = "Nixpkgs overlays";
    };
    config = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = { };
      description = "The configuration for nixpkgs.";
    };
  };

  config = {
    overlays = lib.mkOrder 200 topConfig.nixpkgs.overlays;
    config = topConfig.nixpkgs.config;
  };
}
