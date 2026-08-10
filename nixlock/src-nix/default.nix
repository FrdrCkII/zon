{
  config ? { },
  extraTypes ? _: { },
  inputs ? { },
  locked ? { },
  ...
}:
{ update }:
let
  nllib = import ./nllib.nix allArgs;
  defaultTypes = import ./defaultTypes.nix allArgs;
  types = defaultTypes // (extraTypes allArgs);

  allArgs = {
    config = import ./makeConfig.nix locked config;
    inherit (allArgs.config) pkgs lib;
    inherit
      inputs
      locked
      update
      nllib
      types
      ;
  };
in
allArgs
// {
  list = "@nixlock;@isString;" + (builtins.concatStringsSep ";" (builtins.attrNames inputs));
}
