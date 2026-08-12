final: prev: {
  nixlock-unwrapped = prev.callPackage ./package/package.nix { };
  nixlock = prev.callPackage ./package/wrapper.nix { };
}
