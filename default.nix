import ./modnix {
  outputs = { mod, ... }: {
    falake = import ./falake;
    modnix = mod.init;
    nixlock = import ./nixlock;
    withInputs = import ./with-inputs;
    wrapit = import ./wrapit;
    zonfig = mod.sub ./zonfig;
  };
}
