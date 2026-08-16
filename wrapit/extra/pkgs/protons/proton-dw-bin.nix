{ protons }:
let
  channel = import ../../channels.nix;
in
protons.proton-bin.override {
  src = channel.expr.dwproton;
  pname = "proton-dw-bin";
  steamDisplayName = "DW-Proton";
  version = builtins.head (
    builtins.match ".*/(dwproton-[^/]+)\\.tar\\.xz" channel.locked.dwproton.url
  );
}
