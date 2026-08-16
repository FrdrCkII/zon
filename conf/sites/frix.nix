{
  inputs,
  config,
  lib,
  ...
}:
{
  outputs = {
    nixosConfigurations = {
      fx-is = inputs.zon.zonfig.init {
        inherit inputs;
        specialArgs = { inherit inputs; };

        module = {
          builtinModules = {
            enableAll = true;
          };

          sharedModules = [
            ../share/desktop
            ../share/programs/firefox
            ../share/programs/pnginx
            ./frix/hardware
          ];

          evalArgs = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
          };

          root = {
            rootTarget = "nixos";

            nixpkgs = {
              inherit (config.nixpkgs) overlays;
            };

            extraModules = {
              nixos.imports = [
                ../share/shell/bash.nix
                ./frix/secret/nixos.nix
                ./frix/minial.nix
                inputs.nixos-core.nixosModules.nixos-core
                {
                  system.etc.overlay.enable = lib.mkForce false;
                  services.userborn.enable = lib.mkForce false;
                  system.nixos-core.enable = true;
                }
              ];
              nixos-hjem = {
                hjem = {
                  specialArgs = { inherit inputs; };
                  clobberByDefault = true;
                };
              };
            };

            os = {
              base = {
                disableCoredump = true;
              };
              boot = {
                loader = "systemd-boot";
              };
              network = {
                wireless = "iwd";
                dns = null;
              };
              nix = {
                # implementation = "lix";
                implementation = "nix";
              };
            };

            gui = {
              theme.enable = true;
              displayManager.package = "emptty";
            };
          };

          node = {
            main = {
              nodeTarget = [
                "user"
                "hjem"
              ];

              info = {
                user = "main";
              };
            };
          };
        };
      };

      fx-def = config.outputs.nixosConfigurations.fx-is.extend {
        sharedModules = [
          ../share/programs/steam
        ];

        root = {
          extraModules = {
            nixos.imports = [
              ./frix/full.nix
            ];
          };
        };
      };
    };
  };
}
