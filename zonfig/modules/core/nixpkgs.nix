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
          inherit (cfg) config;
          overlays = lib.mkBefore cfg.overlays;
        };
      };
    };
  };
}
