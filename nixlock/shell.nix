let
  pkgs = import <nixpkgs> {
    overlays = [ (import ./default.nix).overlays.nixlock ];
  };
in
pkgs.mkShell {
  packages = [
    pkgs.nixlock
  ];
}
