{ pkgs, ... }: {
  system = {
    stateVersion = "26.05";
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
      useTmpfs = true;
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
      pkgs.nvtopPackages.intel
      pkgs.nvtopPackages.nvidia
      pkgs.nixos-facter
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
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

    nvidia.open = true;

    graphics = {
      extraPackages = [
        pkgs.intel-compute-runtime
        pkgs.intel-compute-runtime.drivers
        pkgs.intel-media-driver
        pkgs.libvdpau-va-gl
        pkgs.vpl-gpu-rt
        pkgs.libvpl
      ];
      extraPackages32 = [
        pkgs.pkgsi686Linux.intel-media-driver
      ];
    };
  };

  nix.settings.system-features = [
    "gccarch-arrowlake-s"
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
  ];
}
