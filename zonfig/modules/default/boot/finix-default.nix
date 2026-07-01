{ lib, ... }: {
  config = {
    boot = {
      kernelParams = [
        "nowatchdog"
      ];
      loader = {
        efi.canTouchEfiVariables = true;
        efi.efiSysMountPoint = lib.mkDefault "/boot";
      };
    };
  };
}
