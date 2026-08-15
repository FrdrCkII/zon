{
  channels,
  protons,
  ...
}:
protons.proton-bin.override {
  src = "${channels.inputs.dwproton}";
  pname = "proton-dw-bin";
  steamDisplayName = "DW-Proton";
  version = builtins.head (
    builtins.match ".*/(dwproton-[^/]+)\\.tar\\.xz" channels.channels.locked.dwproton.url
  );
}
