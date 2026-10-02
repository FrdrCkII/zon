{
  pkgs ? import <nixpkgs> { },
}:
{
  oxidns = pkgs.callPackage ./package.nix { };
}
