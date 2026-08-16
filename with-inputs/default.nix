{
  inputs,
  config ? { },
  speacialArgs ? { },
  outputs,
  ...
}:
let
  normalizeSource =
    source: if builtins.isAttrs source then source else { outPath = builtins.toString source; };

  flakeSettings =
    meta:
    let
      f = meta.flake or true;
    in
    if builtins.isBool f then
      {
        enable = f;
        path = "flake.nix";
      }
    else if builtins.isString f then
      {
        enable = true;
        path = f;
      }
    else if builtins.isAttrs f then
      {
        enable = f.enable or true;
        path = f.path or "flake.nix";
      }
    else
      {
        enable = true;
        path = "flake.nix";
      };

  mkInputs =
    name: source:
    let
      sourceInfo = normalizeSource source;
      lockInfo = config.${name} or { };
      flakeInfo = flakeSettings lockInfo;

      flakePath = "${builtins.toString sourceInfo.outPath}/${flakeInfo.path}";

      resolveFollow =
        inputName: _value:
        let
          followKey =
            if lockInfo ? follows && builtins.isAttrs lockInfo.follows then
              lockInfo.follows.${inputName} or inputName
            else
              inputName;
        in
        inputsWithFollows.${followKey} or { };
    in
    if flakeInfo.enable && builtins.pathExists flakePath then
      let
        flake = import flakePath;
        flakeInputs = builtins.mapAttrs resolveFollow (flake.inputs or { });
        flakeOutputs = flake.outputs (flakeInputs // { inherit self; });

        self =
          sourceInfo
          // flakeOutputs
          // {
            _type = "flake";
            inputs = flakeInputs;
            outputs = flakeOutputs;
            inherit sourceInfo;
          };
      in
      self
    else
      sourceInfo // { inherit sourceInfo; };

  inputsWithFollows = builtins.mapAttrs (name: value: mkInputs name value) inputs;

  inputsWithSelf = inputsWithFollows // {
    self =
      speacialArgs
      // {
        inputs = inputsWithFollows;
        outputs = result;
      }
      // result;
  };

  result = outputs inputsWithSelf;
in
result
