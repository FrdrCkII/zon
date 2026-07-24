let
  zon = import ../default.nix;
  channels = import ./channels.nix;
in
zon.nixlock.lib.withInputs {
  inputs = (builtins.mapAttrs (n: v: v.expr) channels.locked) // {
    zon = (import ../default.nix) // {
      outPath = ../.;
    };
  };

  inputsMeta = channels.inputs // {
    zon = { };
  };

  extraArgs = {
    outPath = ./.;
  };

  outputFun =
    inputs:
    inputs.zon.falake.lib.mkFalake {
      nixpkgs = "${inputs.nixpkgs}";
      specialArgs = { inherit inputs; };
      module = { lib, ... }: {
        imports = [
          ./dev
          ./sites/frix.nix
        ];

        config = {
          allSystems = {
            "x86_64-linux" = { };
          };

          nixpkgs = {
            overlays = [
              inputs.zon.nixlock.overlays.nixlock
              inputs.zon.wrapit.overlays.wrapit
              inputs.zon.wrapit.overlays.extra
              inputs.zon.wrapit.overlays.conf
              (_: _: { inherit inputs; })
              (import ./overlay.nix)
            ];
          };
        };
      };
    };
}
