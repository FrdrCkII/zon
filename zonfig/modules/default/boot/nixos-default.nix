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
        "udev.log_level=${toString config.boot.consoleLogLevel}"
        "nowatchdog"
      ];
      loader = {
        timeout = lib.mkDefault 3;
        efi.canTouchEfiVariables = true;
        efi.efiSysMountPoint = lib.mkDefault "/boot";
      };
    };
  };
}
