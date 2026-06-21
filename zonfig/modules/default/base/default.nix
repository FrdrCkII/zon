{
  config,
  lib,
  ...
}:
let
  cfg = config.os.base;
in
{
  options = {
    os.base = {
      default = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      defaultPackages = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      disableCoredump = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      overlayfsEtc = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      doc = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      xdgPath = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      extra = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = {
    iNeedDirectories = {
      host = [
        "/var/lib/nixos"
        "/var/lib/private"
        "/etc/machine-id"
      ]
      ++ lib.optionals cfg.overlayfsEtc [
        "/etc"
        "/.rw-etc/upper/machine-id"
      ]
      ++ lib.optionals cfg.extra [
        "/var/lib/fwupd"
        "/var/lib/power-profiles-daemon"
      ];
    };

    outModules = {
      nixos.imports =
        [ ]
        ++ lib.optionals cfg.default [
          ./nixos-default.nix
          ./nixos-unfree.nix
        ]
        ++ lib.optional cfg.defaultPackages ./nixos-packages.nix
        ++ lib.optional cfg.disableCoredump ./nixos-coredump.nix
        ++ lib.optional cfg.overlayfsEtc ./nixos-etc.nix
        ++ lib.optional cfg.doc ./nixos-doc.nix
        ++ lib.optional cfg.xdgPath ./nixos-xdg.nix
        ++ lib.optional cfg.extra ./nixos-extra.nix;
    };
  };
}
