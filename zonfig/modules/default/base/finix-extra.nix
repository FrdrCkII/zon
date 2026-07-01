{
  modules,
  lib,
  ...
}:
{
  imports = [
    modules.fwupd
    modules.power-profiles-daemon
    modules.gnome-keyring
  ];

  config = {
    services.fwupd.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;
    programs.gnome-keyring.enable = lib.mkDefault true;
  };
}
