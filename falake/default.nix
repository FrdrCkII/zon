let
  eval = import ./top-level;
in
{
  lib = {
    inherit eval;
    mkFalake = args: (eval args).config.out;
  };
}
