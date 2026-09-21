let
  pkgs = import <nixpkgs> { };
in
pkgs.mkShell {
  packages = [
    pkgs.python3
    pkgs.toml-sort
    pkgs.alejandra
    pkgs.nixfmt
  ];
}
