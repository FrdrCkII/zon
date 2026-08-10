allArgs@{
  update,
  locked,
  lib,
  ...
}:
let
  allTypeArgs = allArgs // allArgs.nllib // { inherit types; };

  types =
    let
      dir = ./types;

      dirMap = builtins.mapAttrs (
        n: v:
        if v == "regular" && builtins.match "^(.*)\\.nix$" n != null then
          {
            name = builtins.head (builtins.match "^(.*)\\.nix$" n);
            value = import "${dir}/${n}" allTypeArgs;
          }
        else
          null
      ) (builtins.readDir dir);

      dirAttrs = builtins.listToAttrs (builtins.attrValues dirMap);
    in
    dirAttrs;
in
types
