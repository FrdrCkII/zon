{
  outModules = {
    nixos.imports = [
      ./nixos
    ];
    hjem.imports = [
      ./hjem
    ];
  };
}
