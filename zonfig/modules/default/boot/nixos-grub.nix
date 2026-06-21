{ lib, ... }: {
  config = {
    boot.loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      gfxmodeEfi = lib.mkDefault "1920x1080@60";
      gfxpayloadEfi = lib.mkDefault "keep";
      configurationName = lib.mkDefault "GRUB";
      configurationLimit = lib.mkDefault 10;
    };
  };
}
