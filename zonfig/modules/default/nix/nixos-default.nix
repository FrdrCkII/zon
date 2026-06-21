{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  config = {
    nix = {
      settings = {
        auto-optimise-store = lib.mkDefault true;
        builders-use-substitutes = lib.mkDefault true;
        use-xdg-base-directories = lib.mkDefault true;
        trusted-users = [
          "root"
          "@wheel"
        ];
        allowed-users = [
          "root"
          "@wheel"
        ];
        experimental-features = [
          "nix-command"
        ];
      };

      nixPath = lib.mkForce (
        lib.mapAttrsToList (name: lib.const "${name}=/run/current-system/inputs/${name}") inputs
      );
    };

    system.systemBuilderCommands = ''
      ln -s ${
        pkgs.linkFarm "flake-inputs" (lib.mapAttrs (lib.const (flake: flake.outPath)) inputs)
      } $out/inputs
    '';
  };
}
