{ pkgs, ... }: {
  imports = [
    ./bash.nix
  ];
  users = {
    defaultUserShell = pkgs.frix.brush;
  };
  environment.shells = [
    pkgs.frix.brush
  ];
}
