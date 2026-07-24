{
  outModules = {
    nixos.imports = [
      ./nixos.nix
      ./fcitx5.nix
    ];
  };
}
