let
  loadMod =
    inputs: root: super: args:
    let
      tryLoad =
        path: import (if builtins.readFileType path == "directory" then path + "/mod.nix" else path);
      tryEval =
        args:
        if builtins.isPath args then
          tryLoad args
        else if builtins.isAttrs args && args ? __path && args.__isPath or false == true then
          tryLoad args.__path
        else
          args;

      expr = tryEval args;
      self =
        if builtins.isFunction expr then
          let
            load = loadMod inputs root self;

            loadDir =
              dir:
              builtins.mapAttrs (_: v: load v) (
                builtins.listToAttrs (
                  builtins.filter (v: builtins.isAttrs v && v != { }) (
                    builtins.attrValues (
                      builtins.mapAttrs (
                        n: v:
                        if builtins.match "^[._-]" n != null || n == "mod.nix" then
                          null
                        else if v == "directory" then
                          if builtins.pathExists "${dir}/${n}/mod.nix" then
                            {
                              name = n;
                              value = {
                                __isPath = true;
                                __path = "${dir}/${n}/mod.nix";
                              };
                            }
                          else
                            {
                              name = n;
                              value = { mod, ... }: mod.loadDir "${dir}/${n}";
                            }
                        else if v == "regular" && builtins.match "^(.*)\\.nix$" n != null then
                          {
                            name = builtins.head (builtins.match "^(.*)\\.nix$" n);
                            value = {
                              __isPath = true;
                              __path = "${dir}/${n}";
                            };
                          }
                        else
                          null
                      ) (builtins.readDir dir)
                    )
                  )
                )
              );

            sub =
              args:
              let
                expr = tryEval args;
                inputs = expr.inputs or { };
                outputs = expr.outputs or { };
              in
              init {
                inherit outputs;
                inputs = inputs // {
                  crate = root;
                };
              };

            args = inputs // {
              inherit root super self;
              mod = {
                inherit
                  init
                  load
                  loadDir
                  sub
                  ;
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
      root = makeOverrides inputs outputs (loadMod inputs root { } outputs);
    in
    root;
in
init
