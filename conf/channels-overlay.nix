inputs: _: _: {
  channels = {
    inherit inputs;
    channels = import ./channels.nix;
  };
}
