{
  config,
  lib,
  ...
}:
let
  cfg = config.gui.theme;
in
{
  options = {
    gui.theme = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    outModules = {
      nixos.imports = [
        ./nixos-default.nix
      ];

      hjem.imports = [
        ./hjem-default.nix
      ];
    };
  };
}
