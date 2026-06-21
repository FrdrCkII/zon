{
  config,
  lib,
  ...
}:
{
  options = {
    subModules = {
      outputs = lib.mkOption {
        type = lib.types.listOf lib.types.deferredModule;
        default = [ ];
        description = "Extra subModule list for {option}`outputs`.";
      };
    };

    outputs = lib.mkOption {
      type = lib.types.submoduleWith {
        class = "outputs";
        modules = [ ../outputs ] ++ config.subModules.outputs;
        specialArgs = {
          topConfig = config;
        };
      };
      default = { };
      description = ''
        Raw flake output attributes. Any attribute can be set here, but some
        attributes are represented by options, to provide appropriate
        configuration merging.
      '';
    };

    out = lib.mkOption {
      type = lib.types.attrs;
      description = ''
        The `outputs` option after removing duplicates
      '';
      readOnly = true;
    };
  };

  config = {
    out = lib.filterAttrs (_: v: !(v == null || (builtins.isAttrs v && v == { }))) config.outputs;
  };
}
