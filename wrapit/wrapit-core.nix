final: prev: {
  wrapit = prev.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (prev) callPackage;
    directory = ../wrapit-core;
  };
}
