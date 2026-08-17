import ./modnix {
  outputs = { mod, ... }: {
    falake = import ./falake;
    modnix = mod.init;
    nixlock = import ./nixlock;
    withInputs = import ./with-inputs;
    wrapit = mod.sub ./wrapit;
    zonfig = mod.sub ./zonfig;
  };
}
