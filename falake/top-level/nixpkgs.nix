{
  nixpkgs,
  config,
  lib,
  ...
}:
{
  options = {
    nixpkgs = {
      src = lib.mkOption {
        type = lib.types.path;
        default = nixpkgs;
        description = "Path to nixpkgs";
      };
      config = lib.mkOption {
        type = with lib.types; attrsOf unspecified;
        default = { };
        description = "The configuration for nixpkgs.";
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
    };

    systems = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          class = "systems";
          modules = [
            ./subSystem.nix
          ];
          specialArgs = {
            topConfig = config;
          };
        }
      );
      default = { };
      description = ''
        All the system types to enumerate in the flake output subattributes.
      '';
    };

    allPkgs = lib.mkOption {
      type = with lib.types; attrsOf unspecified;
      description = "The system-specific config for each of systems.";
      readOnly = true;
    };
  };

  config = {
    allPkgs = lib.mapAttrs (
      n: v:
      import "${config.nixpkgs.src}/pkgs/top-level/default.nix" {
        inherit (v)
          localSystem
          crossSystem
          overlays
          config
          ;
      }
    ) config.systems;
  };
}
