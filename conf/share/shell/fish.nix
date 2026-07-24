{ pkgs, ... }: {
  imports = [
    ./bash.nix
  ];
  users = {
    defaultUserShell = pkgs.fish;
  };
  programs = {
    fish = {
      enable = true;
    };
  };
}
