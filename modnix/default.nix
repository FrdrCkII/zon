let
  fix =
    f:
    let
      x = f x;
    in
    x;

  loadMod = fix (
    loadMod: init: inputs: root: super: args:
    let
      isPathWrapper = args: builtins.isAttrs args && args ? __path && (args.__isPath or false) == true;
      toPathValue = path: {
        __isPath = true;
        __path = path;
      };
      importPath =
        path:
        import (if builtins.readFileType path == "directory" then path + "/default.mod.nix" else path);
      resolve =
        args:
        if builtins.isPath args then
          importPath args
        else if isPathWrapper args then
          importPath args.__path
        else
          args;

      expr = resolve args;
    in
    fix (
      self:
      let
        setRoot = if root == null then self else root;

        load = loadMod init inputs setRoot self;
        loadSub = loadMod init inputs null self;

        loadDir = fix (
          loadDir: dir:
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
                  m = builtins.match "^(.*)\\.mod.nix$" name;
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
          builtins.mapAttrs (_: load) (builtins.listToAttrs loadable)
        );
      in
      expr (
        inputs
        // {
          inherit super self;
          root = setRoot;
          mod = {
            inherit
              init
              load
              loadDir
              loadSub
              ;
          };
        }
      )
    )
  );

  init = fix (
    init: loadMod:
    {
      inputs ? { },
      outputs ? { },
    }:
    fix (
      self:
      (fix (
        mkOverride: inputs: outputs: root:
        root
        // {
          __inputs = inputs;
          __override =
            overlay:
            let
              inputsNew = fix (final: inputs // (overlay final inputs));
              rootNew = fix (self': loadMod init inputsNew self' { } outputs);
            in
            mkOverride inputsNew outputs rootNew;
        }
      ))
        inputs
        outputs
        (loadMod init inputs self { } outputs)
    )
  );
in
init loadMod
