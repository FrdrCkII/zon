{ lib, ... }: {
  config = {
    networking.wireless = {
      enable = true;
      userControlled = {
        enable = lib.mkDefault true;
        group = lib.mkDefault "wheel";
      };
    };
  };
}
