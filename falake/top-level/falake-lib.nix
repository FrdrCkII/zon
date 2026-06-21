lib:
let
  mkTransposedPerSystemModule =
    {
      name,
      file,
      option,
    }:
    {
      outputs.imports = lib.singleton {
        _class = "outputs";
        _file = file;

        options = {
          ${name} = lib.mkOption {
            type = lib.types.attrsWith {
              elemType = option.type;
              lazy = true;
              placeholder = "system";
            };
            default = { };
            description = ''
              See {option}`perSystem.${name}` for description and examples.
            '';
          };
        };
      };

      perSystem.imports = lib.singleton {
        _class = "perSystem";
        _file = file;

        options.${name} = option;
      };
    };
in
{
  inherit mkTransposedPerSystemModule;
}
