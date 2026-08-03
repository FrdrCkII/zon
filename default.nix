import ./modnix {
  outputs =
    {
      load,
      init,
      ...
    }:
    {
      modnix = init;
      wrapit = load ./wrapit;
      zonfig = load ./zonfig;
    };
}
