{ pkgs, ... }: {
  config = {
    nix.package = pkgs.lixPackageSets.stable.lix;
  };
}
