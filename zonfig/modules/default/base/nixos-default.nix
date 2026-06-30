{ lib, ... }: {
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
      defaultPackages = lib.mkForce [ ];
      variables = {
        EDITOR = lib.mkDefault "nano";
        VISUAL = lib.mkDefault "nano";
      };
      sessionVariables = {
        LIBSEAT_BACKEND = "seatd";
      };
    };

    programs = {
      nano = {
        enable = lib.mkDefault true;
      };

      git = {
        enable = lib.mkDefault true;
        config = {
          init = {
            defaultBranch = "main";
          };
          url = {
            "https://github.com/".insteadOf = lib.singleton "gh:";
            "https://codeberg.org/".insteadOf = lib.singleton "cb:";
          };
        };
      };
    };

    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };

    services = {
      udev.enable = true;
      dbus.implementation = "broker";
      libinput.enable = true;

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
      tpm2.enable = false;
      oomd.enable = false;
    };
  };
}
