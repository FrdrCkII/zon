{
  config,
  lib,
  ...
}:
let
  cfg = config.os.network;
in
{
  options = {
    os.network = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      wireless = lib.mkOption {
        type = lib.types.enum [
          null
          "wpa"
          "iwd"
          "nm-wpa"
          "nm-iwd"
        ];
        default = "iwd";
      };

      dns = lib.mkOption {
        type = lib.types.enum [
          null
          "dnsmasq"
        ];
        default = "dnsmasq";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    os.network.wireless = lib.mkIf (config.rootTarget == "finix") (lib.mkForce "iwd");

    iNeedDirectories = {
      host =
        lib.optional (cfg.wireless == "iwd") "/var/lib/iwd"
        ++ lib.optional (cfg.wireless == "nm-wpa") "/var/lib/NetworkManager"
        ++ lib.optional (cfg.wireless == "nm-iwd") "/var/lib/NetworkManager";
    };

    outModules = {
      nixos.imports = [
        ./nixos-default.nix
      ]
      ++ lib.optional (cfg.wireless == "wpa") ./nixos-wpa.nix
      ++ lib.optional (cfg.wireless == "iwd") ./nixos-iwd.nix
      ++ lib.optional (cfg.wireless == "nm-wpa") ./nixos-nm-wpa.nix
      ++ lib.optional (cfg.wireless == "nm-iwd") ./nixos-nm-iwd.nix;

      finix.imports = [
        ./finix-default.nix
      ]
      ++ lib.optional (cfg.wireless == "iwd") ./finix-iwd.nix;
    };
  };
}
