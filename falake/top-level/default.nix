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
    (lib.modules.importApply ./nixpkgs.nix { inherit nixpkgs; })
    ./outputs.nix
    ../outputs
    ./systems.nix
    ../perSystem
  ];
  specialArgs = lib.recursiveUpdate specialArgs {
    inherit falake;
  };
}
