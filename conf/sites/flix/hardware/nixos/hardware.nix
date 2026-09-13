{ pkgs, ... }: {
  system = {
    stateVersion = "26.11";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [
      "kvm-intel"
      "ntsync"
    ];

    kernelParams = [
      "nmi_watchdog=1"
      "hardlockup_panic=1"
      "panic_timeout=10"
    ];

    tmp = {
      cleanOnBoot = true;
    };

    initrd = {
      includeDefaultModules = false;
      availableKernelModules = [
        "nvme"

        "xhci_hcd"
        "xhci_pci"
        "usb_storage"
        "usbhid"
        "dm_mod"

        "ahci"
      ];
      kernelModules = [
        "i915"
        "xe"
      ];
    };

    zswap = {
      enable = true;
      compressor = "zstd";
      zpool = "zsmalloc";
    };
  };

  environment = {
    systemPackages = [
      pkgs.nixos-facter
    ];
  };

  hardware = {
    facter = {
      enable = true;
      reportPath = ./hardware.facter.json;
    };

    enableAllFirmware = false;
    enableRedistributableFirmware = false;
    firmware = [
      pkgs.linux-firmware
      pkgs.sof-firmware
    ];

    cpu.intel = {
      updateMicrocode = true;
    };

    graphics = {
      enable = true;
      extraPackages = [
        pkgs.intel-compute-runtime
        pkgs.intel-media-driver
        pkgs.libvdpau-va-gl
        pkgs.vpl-gpu-rt
        pkgs.libvpl
      ];
      extraPackages32 = [
        pkgs.pkgsi686Linux.intel-media-driver
      ];
    };

    nvidia = {
      open = true;
      branch = "latest";

      gsp.enable = true;
      modesetting.enable = true;

      videoAcceleration = true;
      nvidiaSettings = true;

      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;

        intelBusId = "PCI:0@0:2:0";
        nvidiaBusId = "PCI:1@0:0:0";
      };

      powerManagement = {
        enable = true;
        finegrained = false;
      };
    };
  };

  services = {
    xserver.videoDrivers = [
      "modsetting"
      "nvidia"
    ];
  };

  nixpkgs = {
    allowUnfreePredicate = [
      "nvidia-x11"
      "nvidia-settings"
      "nvidia-kernel-modules"
    ];
  };

  nix.settings.system-features = [
    "gccarch-arrowlake-s"
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
  ];
}
