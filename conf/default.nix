let
  zon = import ../default.nix;
  channels = import ./channels.nix;
in
zon.withInputs {
  inputs = channels.expr // {
    zon = (import ../default.nix) // {
      outPath = ../.;
    };
  };

  speacialArgs = {
    outPath = ./.;
  };

  outputs =
    inputs:
    inputs.zon.falake.lib.mkFalake {
      nixpkgs = "${inputs.nixpkgs}";
      specialArgs = { inherit inputs; };
      module = { lib, ... }: {
        imports = [
          ./dev
          ./sites/frix.nix
          ./sites/flix.nix
        ];

        config = {
          allSystems = {
            "x86_64-linux" = { };
          };

          nixpkgs = {
            overlays = [
              inputs.zon.nixlock.overlay
              inputs.zon.wrapit.overlays.wrapit
              inputs.zon.wrapit.overlays.extra
            ];
          };
        };
      };
    };
}
