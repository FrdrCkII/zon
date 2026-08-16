{
  pkgs,
  lib,
  ...
}:
{
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
      mutableUsers = lib.mkDefault false;
      users.root.hashedPassword = lib.mkDefault "!";
    };

    environment = {
      defaultPackages = lib.mkForce [
        pkgs.git
        pkgs.nano
      ];
      sessionVariables = {
        EDITOR = lib.mkDefault "nano";
        VISUAL = lib.mkDefault "nano";
        LIBSEAT_BACKEND = "seatd";
      };
    };

    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };

    services = {
      udev.enable = true;
      udisks2.enable = true;
      libinput.enable = true;
      dbus.implementation = "broker";

      chrony.enable = true;
      timesyncd.enable = false;

      userborn.enable = true;

      journald = {
        extraConfig = ''
          SystemMaxUse=500M
          RuntimeMaxUse=200M
          SystemKeepFree=1G
          RuntimeKeepFree=500M
          MaxFileSec=1week
        '';
      };

      seatd = {
        enable = lib.mkDefault true;
        group = "video";
      };

      pipewire = {
        enable = lib.mkDefault true;
        alsa.enable = lib.mkDefault true;
        alsa.support32Bit = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
        jack.enable = lib.mkDefault true;
        wireplumber = {
          enable = lib.mkDefault true;
        };
      };
    };

    systemd = {
      oomd.enable = false;
    };
  };
}
