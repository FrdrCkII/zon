{
  inputs ? { },
  nixpkgs ? inputs.nixpkgs,
  specialArgs ? { },
  module ? { },
  ...
}:
let
  lib = import "${nixpkgs}/lib";
  eval = lib.evalModules {
    class = "zonfig-toplevel";
    modules = [
      module
      ./targets.nix
      ./extendModules.nix
    ];
    specialArgs = lib.recursiveUpdate specialArgs {
      zon = {
        inherit inputs nixpkgs;
        modulesPath = ../modules;
      };
    };
  };
in
eval.config.out
