{ lib, ... }: {
  _class = "falake";

  config.outputs.imports = lib.singleton {
    _class = "outputs";
    _file = ./nixosConfigurations.nix;

    options = {
      nixosConfigurations = lib.mkOption {
        type = with lib.types; lazyAttrsOf raw;
        default = { };
        description = ''
          Instantiated NixOS configurations. Used by `nixos-rebuild`.

          `nixosConfigurations` is for specific machines. If you want to expose
          reusable configurations, add them to [`nixosModules`](#opt-flake.nixosModules)
          in the form of modules (no `lib.nixosSystem`), so that you can reference
          them in this or another flake's `nixosConfigurations`.
        '';
        example = lib.literalExpression ''
          {
            my-machine = inputs.nixpkgs.lib.nixosSystem {
              # system is not needed with freshly generated hardware-configuration.nix
              # system = "x86_64-linux";  # or set nixpkgs.hostPlatform in a module.
              modules = [
                ./my-machine/nixos-configuration.nix
                config.nixosModules.my-module
              ];
            };
          }
        '';
      };
    };
  };
}
