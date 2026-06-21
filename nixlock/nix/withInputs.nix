{
  inputs,
  inputsMeta,
  extraArgs,
  outputFun,
}:
let
  mkInputs =
    name: source:
    let
      sourceInfo = if builtins.isString source then { outPath = source; } else source;
      lockInfo = inputsMeta.${name};
      flakeInfo = import ./isFlake.nix lockInfo;
      flakePath = sourceInfo + "/" + flakeInfo.path;
      inputsFollow = name: _value: inputsWithFollows.${lockInfo.follows.${name} or name} or { };
    in
    if flakeInfo.enable && builtins.pathExists flakePath then
      let
        flake = import (sourceInfo.outPath + "/flake.nix");
        inputs = builtins.mapAttrs inputsFollow (flake.inputs or { });
        outputs = flake.outputs (inputs // { inherit self; });
        self =
          sourceInfo
          // outputs
          // {
            _type = "flake";
            inherit inputs outputs sourceInfo;
          };
      in
      self
    else
      sourceInfo
      // {
        inherit sourceInfo;
      };
  inputsWithFollows = builtins.mapAttrs (name: value: mkInputs name value) inputs;
  inputsWithSelf = inputsWithFollows // {
    self = extraArgs // { inputs = inputsWithFollows; } // { inherit outputs; } // outputs;
  };
  outputs = outputFun inputsWithSelf;
in
outputs
