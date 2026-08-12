let
  pkgs = import <nixpkgs> {
    overlays = [ (import ./overlay.nix) ];
  };
in
pkgs.mkShell {
  packages = [
    pkgs.nixlock
  ];
}
