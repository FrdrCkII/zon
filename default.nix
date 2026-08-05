import ./modnix {
  outputs = { mod, ... }: {
    modnix = mod.init;
    wrapit = mod.sub ./wrapit;
    zonfig = mod.sub ./zonfig;
  };
}
