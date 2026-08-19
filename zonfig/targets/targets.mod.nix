_:
{
  zon,
  config,
  lib,
  ...
}:
{
  options = {
    rootTarget = lib.mkOption {
      type = lib.types.enum [
        "nixos"
        "finix" # TODO
      ];
      default = "nixos";
    };
    nodeTarget = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "user"
          "home-manager"
          "hjem"
        ]
      );
      default = [ ];
    };

    extraModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
    };
    outModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
    };

    info = {
      inputs = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.unspecified;
        default = zon.inputs or { };
      };
      user = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };

    out = lib.mkOption {
      type = lib.types.deferredModule;
      internal = true;
      readOnly = true;
    };
  };

  config = {
    out.imports =
      lib.optionals (config.nodeTarget == [ ]) [
        config.outModules.${config.rootTarget} or { }
        config.extraModules.${config.rootTarget} or { }
      ]
      ++ lib.optionals (config.rootTarget == "finix" && config.nodeTarget == [ ]) (
        builtins.attrValues (import "${config.info.inputs.finix}/modules")
      )
      ++ lib.optionals (lib.elem "user" config.nodeTarget) [
        config.outModules."${config.rootTarget}-user" or { }
        config.extraModules."${config.rootTarget}-user" or { }
      ]
      ++ lib.optionals (config.rootTarget == "nixos" && lib.elem "home-manager" config.nodeTarget) [
        "${config.info.inputs.home-manager}/nixos"
        config.extraModules."${config.rootTarget}-home-manager" or { }
        {
          home-manager.users.${config.info.user}.imports = [
            config.outModules.home-manager or { }
            config.extraModules.home-manager or { }
          ];
        }
      ]
      ++ lib.optionals (config.rootTarget == "nixos" && lib.elem "hjem" config.nodeTarget) [
        (import "${config.info.inputs.hjem}/modules/nixos").default
        config.extraModules."${config.rootTarget}-hjem" or { }
        {
          hjem.users.${config.info.user}.imports = [
            config.outModules.hjem or { }
            config.extraModules.hjem or { }
          ];
        }
      ]
      ++ lib.optionals (config.rootTarget == "finix" && lib.elem "home-manager" config.nodeTarget) [ ]
      ++ lib.optionals (config.rootTarget == "finix" && lib.elem "hjem" config.nodeTarget) [
        (import "${config.info.inputs.hjem}/modules/finix").default
        config.extraModules."${config.rootTarget}-hjem" or { }
        {
          hjem.users.${config.info.user}.imports = [
            config.outModules.hjem or { }
            config.extraModules.hjem or { }
          ];
        }
      ];
  };
}
