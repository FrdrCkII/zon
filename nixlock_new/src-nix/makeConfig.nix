locked:
{
  defaultHashType ? "sha256",
  nixpkgs ? <nixpkgs>,
  pkgs ? import "${nixpkgs}" { },
  lib ? import "${nixpkgs}/lib",
  ...
}:
{
  inherit
    defaultHashType
    nixpkgs
    pkgs
    lib
    ;
}
