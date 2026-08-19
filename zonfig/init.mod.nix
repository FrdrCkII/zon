{ root, ... }:
{
  inputs ? { },
  nixpkgs ? inputs.nixpkgs or <nixpkgs>,
  specialArgs ? { },
  module ? { },
  ...
}:
let
  lib = import "${nixpkgs}/lib";
  eval = lib.evalModules {
    class = "zonfig-toplevel";
    modules = [ module ] ++ (builtins.attrValues root.top-level);
    specialArgs = lib.recursiveUpdate specialArgs {
      zon = {
        inherit inputs nixpkgs;
      };
    };
  };
in
eval.config.out
