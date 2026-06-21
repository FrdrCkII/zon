{
  config,
  lib,
  ...
}:
{
  options = {
    nixpkgs.allowUnfreePredicate = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
    };
  };

  config = {
    nixpkgs.config.allowUnfreePredicate =
      pkg: builtins.elem (lib.getName pkg) config.nixpkgs.allowUnfreePredicate;
  };
}
