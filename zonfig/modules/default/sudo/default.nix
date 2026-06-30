{
  config,
  lib,
  ...
}:
let
  cfg = config.os.sudo;
in
{
  options = {
    os.sudo = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      package = lib.mkOption {
        type = lib.types.enum [
          "sudo"
          "sudo-rs"
          "doas"
        ];
        default = "sudo-rs";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    outModules = {
      nixos.imports =
        lib.optional (cfg.package == "sudo") ./nixos-sudo.nix
        ++ lib.optional (cfg.package == "sudo-rs") ./nixos-sudo-rs.nix
        ++ lib.optional (cfg.package == "doas") ./nixos-doas.nix;
    };
  };
}
