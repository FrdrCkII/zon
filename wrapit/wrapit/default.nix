final: prev: {
  wrapit = prev.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (prev) callPackage;
    directory = ./pkgs;
  };
}
