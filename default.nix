import ./modnix {
  outputs = { mod, ... }: {
    falake = import ./falake;
    modnix = mod.init;
    nixlock = import ./nixlock;
    nixtools = import ./nixtools;
    withInputs = import ./with-inputs;
    wrapit = mod.loadSub ./wrapit;
    zonfig = mod.loadSub ./zonfig;
  };
}
