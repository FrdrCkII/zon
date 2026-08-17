{
  inputs,
  config,
  lib,
  ...
}:
{
  options.nixpkgs = {
    allowUnfreePredicate = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
    };

    allowCudaUnfree = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = {
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      config.nixpkgs.allowCudaUnfree
      && ((import "${inputs.nixpkgs.outPath}/pkgs/development/cuda-modules/_cuda/default.nix").lib.allowUnfreeCudaPredicate pkg)
      || builtins.elem (lib.getName pkg) config.nixpkgs.allowUnfreePredicate;
  };
}
