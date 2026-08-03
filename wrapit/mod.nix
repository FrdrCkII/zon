let
  makeOverlay = path: final: prev: {
    wrapit = prev.lib.filesystem.packagesFromDirectoryRecursive {
      inherit (prev) callPackage;
      directory = path;
    };
  };
in
{
  wrapit = makeOverlay ./wrapit;
  extra = makeOverlay ./extra;
}
