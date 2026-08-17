{
  pkgs,
  lib,
  ...
}:
{
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

    nvidia = {
      open = true;
      modesetting.enable = true;
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

    libinput = {
      touchpad.tapping = true;
    };
  };

  nixpkgs = {
    allowUnfreePredicate = [
      "nvidia-x11"
      "nvidia-settings"
    ];

    overlays = lib.singleton (
      final: prev: {
        _cuda = prev._cuda // {
          db = prev._cuda.db // {
            redistUrlPrefix = "https://developer.download.nvidia.cn/compute";
          };
        };
      }
    );
  };

  nix.settings.system-features = [
    "gccarch-arrowlake-s"
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
  ];
}
