{ pkgs, ... }: {
  config = {
    nix.package = pkgs.nixVersions.latest;
  };
}
