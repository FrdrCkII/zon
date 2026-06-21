{
  extendModules,
  lib,
  ...
}:
{
  options.extend = lib.mkOption {
    description = "Extend this configuration or submodule with another module";
  };
  config.extend =
    module:
    (extendModules {
      modules = [ module ];
    }).config;
}
