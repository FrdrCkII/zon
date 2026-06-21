{
  config,
  lib,
  ...
}:
{
  _class = "falake";

  options = {
    outputs = lib.mkOption {
      default = { };
      type = lib.types.submoduleWith {
        class = "outputs";
        specialArgs = {
          topConfig = config;
        };
        modules = lib.singleton {
          _class = "outputs";
          _file = ./outputs.nix;

          freeformType = lib.types.lazyAttrsOf (
            lib.types.unique {
              message = ''
                No option has been declared for this flake output attribute, so its definitions can't be merged automatically.
                Possible solutions:
                  - Load a module that defines this flake output attribute
                  - Declare an option for this flake output attribute
                  - Make sure the output attribute is spelled correctly
                  - Define the value only once, with a single definition in a single module
              '';
            } lib.types.raw
          );
        };
      };
      description = ''
        Raw flake output attributes. Any attribute can be set here, but some
        attributes are represented by options, to provide appropriate
        configuration merging.
      '';
    };

    out = lib.mkOption {
      readOnly = true;
      default = config.outputs;
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      apply = v: lib.filterAttrs (_: v: !(v == null || v == { } || v == [ ])) v;
      description = ''
        Usually, the `outputs` option generates some meaningless values (e.g. {}/[]/null)
        because an option has to have a default value.

        This option is used to clean up that noise.
      '';
    };
  };
}
