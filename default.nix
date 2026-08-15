import ./modnix {
  outputs = { mod, ... }: {
    falake = import ./falake;
    modnix = mod.init;
    nixlock = import ./nixlock;
    withInputs = import ./withInputs;
    wrapit = import ./wrapit;
    zonfig = mod.sub ./zonfig;
  };
}
