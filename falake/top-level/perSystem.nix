{
  getSystem,
  config,
  lib,
  ...
}:
{
  imports = [
    ../perSystem
  ];

  options = {
    perSystem = lib.mkOption {
      type = lib.types.deferredModuleWith {
        staticModules = [ { _file = ./perSystem.nix; } ];
      };
      default = { };
      description = ''
        A function from system to flake-like attributes omitting the `<system>` attribute.
      '';
      apply =
        module: system:
        lib.evalModules {
          class = "perSystem";
          prefix = [
            "perSystem"
            system.name
          ];
          specialArgs = {
            system = system.name;
            systemArgs = system;
            pkgs = config.allPkgs.${system.name};
          };
          modules = [
            module
          ];
        };
    };

    evalSystems = lib.mkOption {
      type = with lib.types; lazyAttrsOf unspecified;
      description = "The system-specific evaluation for each of systems.";
      readOnly = true;
    };
    allSystems = lib.mkOption {
      type = with lib.types; lazyAttrsOf unspecified;
      description = "The system-specific config for each of systems.";
      readOnly = true;
    };
  };

  config = {
    evalSystems = builtins.mapAttrs (n: v: config.perSystem v) config.systems;
    allSystems = builtins.mapAttrs (_: value: value.config) config.evalSystems;

    outputs =
      let
        inherit (config) systems;
        systemResults = map getSystem (builtins.attrNames systems);
        allCategories = lib.uniqueStrings (builtins.concatMap builtins.attrNames systemResults);
        buildForCategory =
          category: lib.genAttrs (builtins.attrNames systems) (system: (getSystem system).${category} or { });
        raw = lib.genAttrs allCategories buildForCategory;
      in
      lib.filterAttrsRecursive (_: v: !(v == null || (builtins.isAttrs v && v == { }))) raw;
  };
}
