let
  loadMod =
    inputs: root: super: args:
    let
      expr =
        if builtins.isPath args then
          import (if builtins.readFileType args == "directory" then args + "/mod.nix" else args)
        else
          args;
      self =
        if builtins.isFunction expr then
          let
            args = inputs // {
              inherit root super self;
              load = loadMod inputs root self;
              init = init;
            };
          in
          expr args
        else
          expr;
    in
    self;

  makeOverrides =
    inputs: outputs: root:
    root
    // {
      __inputs = inputs;
      __override =
        overlay:
        let
          inputs' = inputs // (overlay inputs' inputs);
          result = loadMod inputs' result { } outputs;
        in
        makeOverrides inputs' outputs result;
    };

  init =
    {
      inputs ? { },
      outputs ? { },
    }:
    let
      root = loadMod inputs root { } outputs;
      root' = makeOverrides inputs outputs root;
    in
    root';
in
init
