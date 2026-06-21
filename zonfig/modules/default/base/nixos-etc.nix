{
  pkgs,
  lib,
  ...
}:
{
  config = {
    system = {
      etc.overlay.enable = true;
    };
    boot.initrd.systemd = {
      enable = true;
      tpm2.enable = lib.mkDefault false;
    };
    environment.systemPackages = [
      pkgs.composefs
      pkgs.composefs.dev
    ];
  };
}
