{
  outModules = {
    nixos.imports = [
      ./nixos.nix
    ];
    hjem.imports = [
      ./hjem.nix
    ];
  };
}
