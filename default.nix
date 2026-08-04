import ./modnix {
  outputs = { mod, ... }: {
    modnix = mod.init;
    wrapit = mod.load ./wrapit;
    zonfig = mod.load ./zonfig;
  };
}
