{ self, ... }: {
  overlays = {
    default = self.overlays.wrapit;
    wrapit = import ./wrapit-core.nix;
    kernel = import ./wrapit-kernel.nix;
    extra = import ./wrapit-extra.nix;
    conf = import ./wrapit-conf.nix;
  };
}
