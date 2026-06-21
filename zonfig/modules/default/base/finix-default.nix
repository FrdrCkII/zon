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
      # mutableUsers = lib.mkDefault false;
      users.root = {
        password = lib.mkDefault "!";
        # subUidRanges = [
        #   {
        #     startUid = 100000;
        #     count = 65536;
        #   }
        # ];
        # subGidRanges = [
        #   {
        #     startGid = 100000;
        #     count = 65536;
        #   }
        # ];
      };
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
      nano.enable = lib.mkDefault true;
      # dconf.enable = lib.mkDefault true;
      # mtr.enable = lib.mkDefault true;
      # git = {
      #   enable = lib.mkDefault true;
      #   config = {
      #     init = {
      #       defaultBranch = "main";
      #     };
      #     url = {
      #       "https://github.com/".insteadOf = [
      #         "gh:"
      #         "github:"
      #       ];
      #       "https://codeberg.org/".insteadOf = [
      #         "cb:"
      #         "codeberg:"
      #       ];
      #     };
      #   };
      # };
    };
    security = {
      polkit.enable = lib.mkDefault true;
      rtkit.enable = lib.mkDefault true;
    };
    services = {
      # libinput.enable = true;
      # ntpd-rs.enable = lib.mkDefault true;
      # timesyncd.enable = lib.mkDefault false;
      openssh.enable = lib.mkDefault false;
      # userborn.enable = lib.mkDefault true;
      # udev.enable = lib.mkDefault true;
      dbus = {
        enable = lib.mkDefault true;
        # implementation = "broker";
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
    networking = {
      hostId = lib.mkDefault "48b08746";
    };
  };
}
