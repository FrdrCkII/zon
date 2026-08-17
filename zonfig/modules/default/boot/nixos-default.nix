{
  config,
  lib,
  ...
}:
{
  config = {
    boot = {
      consoleLogLevel = lib.mkDefault 3;
      kernelParams = [
        "quiet"
        "udev.log_level=${toString config.boot.consoleLogLevel}"
        "systemd.show_status=auto"
      ];
      loader = {
        timeout = lib.mkDefault 3;
        efi.canTouchEfiVariables = true;
        efi.efiSysMountPoint = lib.mkDefault "/boot";
      };
    };
  };
}
