let
  overlay = final: prev: {
    nixlock = prev.callPackage ./package.nix { };
  };
in
{
  lib.withInputs = import ./nix/withInputs.nix;
  overlay = overlay;
  overlays = {
    default = overlay;
    nixlock = overlay;
  };
}
