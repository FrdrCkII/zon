sources:
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;
in
pkgs.linkFarm "sources" (lib.mapAttrs (lib.const (v: "${toString v}")) sources)
