let
  overlay = final: prev: {
    wrapit = prev.lib.filesystem.packagesFromDirectoryRecursive {
      inherit (prev) callPackage;
      directory = ./pkgs;
    };
  };
in
{
  overlays = {
    default = overlay;
    wrapit = overlay;
  };
}
