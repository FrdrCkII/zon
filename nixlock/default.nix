{
  overlay = _: prev: {
    nixlock = prev.callPackage ./package.nix { };
  };
}
