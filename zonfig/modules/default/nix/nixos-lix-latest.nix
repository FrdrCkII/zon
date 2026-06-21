{ pkgs, ... }: {
  config = {
    nix.package = pkgs.lixPackageSets.latest.lix;
  };
}
