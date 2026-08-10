{
  inputs,
  locked,
  update,
  types,
  pkgs,
  lib,
  ...
}:
let
  nixToString =
    value:
    if lib.isAttrs value && value ? __raw then
      "${value.__raw}"
    else if lib.isAttrs value then
      "{ ${
        lib.concatMapAttrsStringSep " " (
          name: value: "${nixToString { __raw = name; }} = ${nixToString value};"
        ) value
      } }"
    else if lib.isBool value then
      if value then "true" else "false"
    else if lib.isFloat value || lib.isInt value then
      toString value
    else if lib.isFunction value then
      ''"<function>"''
    else if lib.isList value then
      "[ ${lib.concatStringsSep " " (map nixToString value)} ]"
    else if isNull value then
      "null"
    else if lib.isPath value || lib.isString value then
      ''"${builtins.replaceStrings [ "\\" "\n" "\r" "\t" ] [ ''\\'' ''\n'' ''\r'' ''\t'' ] value}"''
    else
      "null";

  makePath =
    packages:
    lib.makeBinPath (
      packages
      ++ [
        pkgs.coreutils-full
        pkgs.gnused
        pkgs.gawk
        pkgs.jq
      ]
    );

  writeBashBin =
    packages: scripts:
    pkgs.writers.writeBashBin "nixlock" { } ''
      set -e
      export PATH=$PATH:${makePath packages}
      ${scripts}
    '';

  writeExeclineBin =
    packages: scripts:
    let
      script = pkgs.execline.passthru.writeScript "/bin/nixlock" "-s0" ''
        export PATH $${PATH}:${makePath packages}
        ${scripts}
      '';
      bin = script.overrideAttrs {
        destination = "/bin/nixlock-el-script";
      };
    in
    bin;

  autoRef =
    ref:
    if isNull ref then
      "HEAD"
    else if builtins.isString ref && lib.hasInfix "/" ref then
      "${ref}"
    else if builtins.isString ref && !lib.hasInfix "/" ref then
      "refs/heads/${ref}"
    else
      "";

  isUpdate = lib.isList update;
  isUpdateAll = update == [ ];
  needUpdate = name: isUpdate && lib.elem name update || isUpdateAll;

  prefetchCommand =
    unpack: hash: url:
    lib.concatStringSep " " [
      "nix"
      "store"
      "prefetch-file"
      "--extra-experimental-features"
      "nix-command"
      "--log-format"
      "internal-json"
      "--json"
      "--no-pretty"
      "--name"
      "source"
      "--hash"
      hash
    ]
    ++ lib.optional unpack "--unpack"
    ++ lib.singleton url;

  # Rust

  matchType = input: types.${inputs.${input}.type};

  matchLen' = input: lib.length (matchType input);
  matchLen = input: nixToString (matchLen' input);

  matchPhase' = input: leng: lib.elemAt (matchType input) leng;
  matchPhase = input: leng: nixToString (matchPhase' input leng);

  matchPhaseName' = input: leng: (matchPhase' input leng).name;
  matchPhaseName = input: leng: nixToString (matchPhaseName' input leng);

  makeInput =
    input: args:
    inputs.${input}
    // args
    // {
      name = input;
      input = inputs.${input};
      locked = locked.${input} or { };
    };

  matchEval' =
    input: leng: args:
    (matchPhase' input leng).eval (makeInput input args);
  matchEval =
    input: leng: args:
    nixToString (matchEval' input leng args);

  matchRun =
    input: leng: args:
    (matchPhase' input leng).run (makeInput input args);
in
{
  inherit
    nixToString
    writeBashBin
    writeExeclineBin
    autoRef
    isUpdate
    isUpdateAll
    needUpdate
    prefetchCommand
    matchType
    matchLen
    matchPhase
    matchPhaseName
    matchEval
    matchRun
    ;
}
