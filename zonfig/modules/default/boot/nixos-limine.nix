{ lib, ... }: {
  config = {
    boot.loader.limine = {
      enable = true;
      maxGenerations = lib.mkDefault 10;
      style.wallpapers = lib.mkForce [ ];
    };
  };
}
