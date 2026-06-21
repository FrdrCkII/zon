{
  nixpkgs,
  specialArgs ? { },
  module ? { },
  ...
}:
let
  lib = import "${nixpkgs}/lib";
  falake = import ./falake-lib.nix lib;
in
lib.evalModules {
  class = "falake";
  modules = [
    module
    ./nixpkgs.nix
    ./outputs.nix
    ./perSystem.nix
    ./withSystem.nix
  ];
  specialArgs = lib.recursiveUpdate specialArgs {
    inherit nixpkgs falake;
  };
}
