{ lib, ... }: {
  config = {
    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        efi.efiSysMountPoint = lib.mkDefault "/boot";
      };
    };
  };
}
