let
  overlay = final: prev: {
    nixlock = prev.callPackage ./package.nix { };
  };
in
{
  lib.withInputs = import ./nix/withInputs.nix;
  overlays = {
    default = overlay;
    nixlock = overlay;
  };
}
