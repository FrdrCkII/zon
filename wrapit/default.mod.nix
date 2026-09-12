{ self, ... }: {
  overlays = {
    default = self.overlays.wrapit;
    wrapit = import ./wrapit-core.nix;
    extra = import ./wrapit-extra.nix;
    conf = import ./wrapit-conf.nix;
  };
}
