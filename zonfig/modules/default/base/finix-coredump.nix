{
  pkgs,
  lib,
  ...
}:
{
  config = {
    boot.kernel.sysctl."kernel.core_pattern" = " | ${lib.getExe' pkgs.coreutils-full "false"}";
  };
}
