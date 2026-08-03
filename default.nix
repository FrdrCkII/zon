import ./modnix {
  inputs = { };
  config = { load }: {
    falake = load ./falake;
    modnix = load ./modnix;
  };
}
