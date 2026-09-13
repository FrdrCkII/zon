final: prev: {
  wLinuxPackages = prev.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (prev) callPackage;
    directory = ../wrapit-kernel;
  };
}
