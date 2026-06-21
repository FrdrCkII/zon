{
  config,
  lib,
  ...
}:
let
  getSystem = system: config.perSystem.${system}.config;
  evalSystem = system: config.perSystem.${system};
  withSystem =
    system: f:
    let
      currentSystem = evalSystem system;
      allModuleArgs =
        currentSystem._module.args
        // currentSystem._module.specialArgs
        // {
          inherit (currentSystem) config options;
        };
    in
    f allModuleArgs;
in
{
  _class = "falake";

  options = {
    perSystem = lib.mkOption {
      default = { };
      type = lib.types.deferredModuleWith {
        staticModules = lib.singleton { _file = ./systems.nix; };
      };
      apply =
        module:
        let
          eval =
            system:
            lib.evalModules {
              class = "perSystem";
              prefix = [
                "perSystem"
                system.name
              ];
              specialArgs = {
                inherit system;
                pkgs = system.pkgs;
              };
              modules = [
                module
              ];
            };
        in
        lib.mapAttrs (n: v: eval v) config.allSystems;
      description = ''
        A function from system to flake-like attributes omitting the `<system>` attribute.
      '';
    };
  };

  config = {
    _module.args = {
      inherit
        getSystem
        evalSystem
        withSystem
        ;
    };

    outputs =
      let
        inherit (config) allSystems;
        systemResults = map getSystem (builtins.attrNames allSystems);
        allCategories = lib.uniqueStrings (builtins.concatMap builtins.attrNames systemResults);
        buildForCategory =
          category:
          lib.genAttrs (builtins.attrNames allSystems) (system: (getSystem system).${category} or { });
        raw = lib.genAttrs allCategories buildForCategory;
      in
      lib.filterAttrsRecursive (_: v: !(v == null || v == { } || v == [ ])) raw;
  };
}
