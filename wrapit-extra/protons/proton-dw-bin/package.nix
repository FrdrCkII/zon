{
  fetchzip,
  protons,
}:
let
  channel = import ./channels.nix;
  this = channel.locked.dwproton;
in
protons.proton-bin.override {
  src = fetchzip {
    url = this.url;
    hash = this.hash;
  };

  pname = "proton-dw-bin";
  steamDisplayName = "DW-Proton";
  version = builtins.head (builtins.match ".*/(dwproton-[^/]+)\\.tar\\.xz" this.url);
}
