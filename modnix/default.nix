let
  fix =
    f:
    let
      x = f x;
    in
    x;

  isPathWrapper = args: builtins.isAttrs args && args ? __path && (args.__isPath or false) == true;

  toPathValue = path: {
    __isPath = true;
    __path = path;
  };

  importPath =
    path:
    import (if builtins.readFileType path == "directory" then path + "/default.mod.nix" else path);

  loadMod =
    inputs: root: super: args:
    let
      resolve =
        args:
        if builtins.isPath args then
          importPath args
        else if isPathWrapper args then
          importPath args.__path
        else
          args;

      expr = resolve args;

      self =
        if !builtins.isFunction expr then
          expr
        else
          let
            load = loadMod inputs root self;

            loadDir =
              dir:
              let
                entries = builtins.readDir dir;

                entryToLoad =
                  name: type:
                  if builtins.match "^[._-]" name != null || name == "default.mod.nix" then
                    null
                  else if type == "directory" then
                    if builtins.pathExists "${dir}/${name}/default.mod.nix" then
                      {
                        inherit name;
                        value = toPathValue "${dir}/${name}/default.mod.nix";
                      }
                    else
                      {
                        inherit name;
                        value = { mod, ... }: mod.loadDir "${dir}/${name}";
                      }
                  else if type == "regular" then
                    let
                      m = builtins.match "^(.*)\\.nix$" name;
                    in
                    if m == null then
                      null
                    else
                      {
                        name = builtins.head m;
                        value = toPathValue "${dir}/${name}";
                      }
                  else
                    null;

                loadable = builtins.filter (x: x != null) (
                  builtins.map (name: entryToLoad name entries.${name}) (builtins.attrNames entries)
                );
              in
              builtins.mapAttrs (_: load) (builtins.listToAttrs loadable);

            sub =
              args:
              let
                expr' = resolve args;
                inputs' = expr'.inputs or { };
                outputs' = expr'.outputs or { };
              in
              init {
                outputs = outputs';
                inputs = inputs' // {
                  crate = root;
                };
              };

            modArgs = inputs // {
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
          expr modArgs;
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
          inputs' = fix (final: inputs // (overlay final inputs));
          result = fix (self': loadMod inputs' self' { } outputs);
        in
        makeOverrides inputs' outputs result;
    };

  init =
    {
      inputs ? { },
      outputs ? { },
    }:
    let
      root = fix (self: makeOverrides inputs outputs (loadMod inputs self { } outputs));
    in
    root;
in
init
