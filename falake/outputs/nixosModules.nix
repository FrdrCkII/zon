{ lib, ... }: {
  options = {
    nixosModules = lib.mkOption {
      type = with lib.types; lazyAttrsOf deferredModule;
      default = { };
      apply = lib.mapAttrs (
        k: v: {
          _class = "nixos";
          _file = "/path/to/flake#nixosModules.${k}";
          imports = [ v ];
        }
      );
      description = ''
        NixOS modules.

        You may use this for reusable pieces of configuration, service modules, etc.
      '';
    };
  };
}
