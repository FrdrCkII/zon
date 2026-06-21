{ lib, ... }: {
  config = {
    services = {
      fwupd.enable = lib.mkDefault true;
      power-profiles-daemon.enable = lib.mkDefault true;
      gnome.gnome-keyring.enable = lib.mkDefault true;
    };
  };
}
