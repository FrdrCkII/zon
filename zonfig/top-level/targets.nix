{
  root,
  super,
  ...
}:
{
  zon,
  config,
  lib,
  ...
}:
let
  bcfg = config.builtinModules;
in
{
  options = {
    sharedModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [ ];
    };

    builtinModules = {
      enableAll = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      default = lib.mkOption {
        type = lib.types.bool;
        default = bcfg.enableAll;
      };
      desktop = lib.mkOption {
        type = lib.types.bool;
        default = bcfg.enableAll;
      };
    };

    root = lib.mkOption {
      type = lib.types.submoduleWith {
        modules = config.sharedModules ++ [
          super.extendModules
        ];
        specialArgs = {
          inherit zon;
        };
      };
      default = { };
    };
    node = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      apply = v: lib.mapAttrs (n: v: config.root.extend v) v;
    };

    evalArgs = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };

    outModules = lib.mkOption {
      type = with lib.types; listOf deferredModule;
      default = [ ];
    };

    out = lib.mkOption {
      description = "out";
    };
  };

  config = {
    sharedModules =
      builtins.attrValues root.targets
      ++ [ root.modules.core ]
      ++ lib.optional config.builtinModules.default root.modules.default
      ++ lib.optional config.builtinModules.desktop root.modules.desktop;

    outModules = [ config.root.out ] ++ (lib.mapAttrsToList (n: v: v.out) config.node);

    out =
      let
        nixpkgs =
          let
            sourceInfo = if builtins.isString zon.nixpkgs then { outPath = zon.nixpkgs; } else zon.nixpkgs;
            flake = import (sourceInfo.outPath + "/flake.nix");
            outputs = flake.outputs { inherit self; };
            self =
              sourceInfo
              // outputs
              // {
                _type = "flake";
                inputs = { };
                inherit outputs sourceInfo;
              };
          in
          self;

        out =
          if config.root.rootTarget == "nixos" then
            nixpkgs.lib.nixosSystem (
              lib.recursiveUpdate config.evalArgs {
                modules = config.outModules;
              }
            )
          else if config.root.rootTarget == "finix" then
            { } # TODO
          else
            { };
      in
      lib.recursiveUpdate out {
        extend = args: (config.extend args).out;
      };
  };
}
