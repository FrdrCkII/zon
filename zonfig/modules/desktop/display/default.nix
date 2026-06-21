{
  config,
  lib,
  ...
}:
let
  cfg = config.gui.displayManager;
in
{
  options = {
    gui.displayManager = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      package = lib.mkOption {
        type = lib.types.enum [
          "ly"
          "lemurs"
          "tuigreet"
          "emptty"
        ];
        default = "ly";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    outModules = {
      nixos.imports = [
        ./nixos-default.nix
      ]
      ++ lib.optional (cfg.package == "ly") ./nixos-ly.nix
      ++ lib.optional (cfg.package == "lemurs") ./nixos-lemurs.nix
      ++ lib.optional (cfg.package == "tuigreet") ./nixos-tuigreet.nix
      ++ lib.optionals (cfg.package == "emptty") [
        ./modules/nixos-emptty.nix
        ./nixos-emptty.nix
      ];
    };
  };
}
