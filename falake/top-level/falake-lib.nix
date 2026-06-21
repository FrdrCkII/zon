lib:
let
  mkTransposedPerSystemModule =
    {
      name,
      file,
      option,
    }:
    {
      subModules.outputs = lib.singleton {
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
      perSystem = { ... }: {
        _file = file;
        options.${name} = option;
      };
    };
in
{
  inherit mkTransposedPerSystemModule;
}
