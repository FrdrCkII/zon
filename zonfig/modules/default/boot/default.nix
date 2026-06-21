{
  config,
  lib,
  ...
}:
let
  cfg = config.os.boot;
in
{
  options = {
    os.boot = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      loader = lib.mkOption {
        type = lib.types.enum [
          "grub"
          "limine"
          "systemd-boot"
        ];
        default = "systemd-boot";
      };
      secureBoot = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    outModules = {
      nixos.imports = [
        ./nixos-default.nix
      ]
      ++ lib.optional (cfg.loader == "grub") ./nixos-grub.nix
      ++ lib.optional (cfg.loader == "limine") ./nixos-limine.nix
      ++ lib.optional (cfg.loader == "limine" && cfg.secureBoot) ./nixos-limine-sb.nix
      ++ lib.optional (cfg.loader == "systemd-boot") ./nixos-sd.nix
      ++ lib.optional (cfg.loader == "systemd-boot" && cfg.secureBoot) ./nixos-sd-sb.nix;
    };
  };
}
