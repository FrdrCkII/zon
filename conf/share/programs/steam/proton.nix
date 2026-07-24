{
  pkgs,
  lib,
  ...
}:
{
  environment = {
    variables = {
      PROTONPATH = lib.mkForce "/run/current-system/sw/share/steam/compatibilitytools.d/DW-Proton";
      WINEPREFIX = "$HOME/.local/share/umu/default";
    };
    systemPackages = [
      pkgs.winetricks
      pkgs.protons.proton-dw-bin.out
    ];
    pathsToLink = [
      "/share/steam"
    ];
  };
  programs = {
    steam.extraCompatPackages = [
      pkgs.protons.proton-dw-bin
    ];
  };
}
