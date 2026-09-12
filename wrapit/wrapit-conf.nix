final: prev: {
  frix = prev.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (prev) callPackage;
    directory = ../wrapit-conf-frix;
  };

  flix = prev.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (prev) callPackage;
    directory = ../wrapit-conf-flix;
  };
}
