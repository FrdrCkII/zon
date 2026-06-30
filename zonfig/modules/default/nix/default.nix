{
  config,
  lib,
  ...
}:
let
  cfg = config.os.nix;
in
{
  options = {
    os.nix = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      implementation = lib.mkOption {
        type = lib.types.enum [
          "nix"
          "nix-latest"
          "lix"
          "lix-latest"
        ];
        default = "nix";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays =
      lib.optional (cfg.implementation == "nix-latest") (import ./nixpkgs-nix-latest.nix)
      ++ lib.optional (cfg.implementation == "lix") (import ./nixpkgs-lix.nix)
      ++ lib.optional (cfg.implementation == "lix-latest") (import ./nixpkgs-lix-latest.nix);

    outModules = {
      nixos.imports = [
        ./nixos-default.nix
      ]
      ++ lib.optional (cfg.implementation == "nix-latest") ./nixos-nix-latest.nix
      ++ lib.optional (cfg.implementation == "lix") ./nixos-lix.nix
      ++ lib.optional (cfg.implementation == "lix-latest") ./nixos-lix-latest.nix;
    };
  };
}
