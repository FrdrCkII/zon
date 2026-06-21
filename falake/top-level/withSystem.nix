{ config, ... }:
let
  getSystem = system: config.allSystems.${system};
  evalSystem = system: config.evalSystems.${system};
  withSystem =
    system: f:
    let
      currentSystem = evalSystem system;
      allModuleArgs =
        currentSystem._module.args
        // currentSystem._module.specialArgs
        // {
          inherit (currentSystem) config options;
        };
    in
    f allModuleArgs;
in
{
  config._module.args = {
    inherit getSystem evalSystem withSystem;
  };
}
