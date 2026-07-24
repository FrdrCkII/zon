{
  inputs,
  protons,
  ...
}:
protons.proton-bin.override {
  src = "${inputs.dwproton}";
  pname = "proton-dw-bin";
  steamDisplayName = "DW-Proton";
  version = builtins.head (
    builtins.match ".*/(dwproton-[^/]+)\\.tar\\.xz" (import ../../channels.nix).locked.dwproton.lock.url
  );
}
