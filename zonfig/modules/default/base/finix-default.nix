{
  modules,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    modules.bash
    modules.pipewire
    modules.sysklogd
    modules.polkit
    modules.rtkit
  ];

  config = {
    boot = {
      kernel.sysctl = {
        "kernel.sysrq" = 1;
      };
      initrd = {
        compressor = "zstd";
        compressorArgs = [
          "-22"
          "-T0"
          "--long"
          "--ultra"
        ];
      };
    };

    hardware = {
      graphics = {
        enable = lib.mkDefault true;
        enable32Bit = lib.mkDefault true;
      };
    };

    users = {
      users.root = {
        password = lib.mkDefault "!";
      };
    };

    environment = {
      defaultPackages = lib.mkForce [
        pkgs.git
        pkgs.nano
      ];
    };

    programs = {
      pipewire = {
        enable = lib.mkDefault true;
        alsa.enable = lib.mkDefault true;
        alsa.support32Bit = lib.mkDefault true;
        jack.enable = lib.mkDefault true;
      };
    };

    security = {
      pam.environment = {
        NIX_PATH.default = "/root/.nix-defexpr/channels:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels";

        EDITOR.default = lib.mkDefault "nano";
        VISUAL.default = lib.mkDefault "nano";
        LIBSEAT_BACKEND.default = "seatd";
      };
    };

    services = {
      sysklogd.enable = true;
      mdevd.enable = true;

      polkit.enable = lib.mkDefault true;
      rtkit.enable = lib.mkDefault true;

      dbus = {
        enable = lib.mkDefault true;
      };

      seatd = {
        enable = lib.mkDefault true;
        group = "video";
      };
    };
  };
}
