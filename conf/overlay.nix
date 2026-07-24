final: prev:
prev.lib.recursiveUpdate prev (
  prev.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (prev) callPackage;
    directory = ./pkgs;
  }
)
