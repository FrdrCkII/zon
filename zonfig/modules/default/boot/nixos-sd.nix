{ lib, ... }: {
  config = {
    boot.loader.systemd-boot = {
      enable = true;
      consoleMode = lib.mkDefault "max";
      configurationLimit = lib.mkDefault 10;
    };
  };
}
