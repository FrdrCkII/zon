{ lib, ... }: {
  options = {
    iNeedDirectories = lib.mkOption {
      type = with lib.types; lazyAttrsOf (listOf str);
      default = { };
    };
    iNeedFiles = lib.mkOption {
      type = with lib.types; lazyAttrsOf (listOf str);
      default = { };
    };
  };
}
