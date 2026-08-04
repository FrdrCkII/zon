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
            load = loadMod inputs root self;

            loadDir =
              dir:
              builtins.mapAttrs (_: v: load v) (
                builtins.listToAttrs (
                  builtins.filter (
                    v:
                    builtins.isAttrs v (
                      builtins.attrValues (
                        builtins.mapAttrs (
                          n: v:
                          if builtins.match "^[._-]" || n == "mod.nix" n then
                            null
                          else if v == "directory" && builtins.pathExists "${dir}/${n}/mod.nix" then
                            {
                              name = n;
                              value = "${dir}/${n}/mod.nix";
                            }
                          else if v == "regular" && builtins.match "\\.nix$" n then
                            {
                              name = builtins.head (builtins.match "^(.*)\\.nix$" n);
                              value = "${dir}/${n}";
                            }
                          else
                            null
                        ) (builtins.readDir dir)
                      )
                    )
                  )
                )
              );

            args = inputs // {
              inherit root super self;
              mod = {
                inherit init load loadDir;
              };
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
