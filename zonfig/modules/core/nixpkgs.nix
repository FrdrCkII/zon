{
  config,
  lib,
  ...
}:
let
  cfg = config.nixpkgs;
in
{
  config = {
    outModules = {
      nixos = {
        nixpkgs = {
          config = cfg.config;
          overlays = lib.mkBefore cfg.overlays;
        };
      };
    };
  };
}
