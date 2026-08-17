{
  inputs,
  config,
  lib,
  ...
}:
{
  outputs = {
    nixosConfigurations = {
      fl-is = inputs.zon.zonfig.init {
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
            ./flix/hardware
            ./frix/common
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
                ./frix/raperl.nix
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
                wireless = "nm-iwd";
                dns = null;
              };
              nix = {
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

      fl-def = config.outputs.nixosConfigurations.fl-is.extend {
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
