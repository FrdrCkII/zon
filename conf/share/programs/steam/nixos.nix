{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./proton.nix
  ];

  nixpkgs = {
    allowUnfreePredicate = [
      "steam"
      "steam-unwrapped"
      "steamcmd"
    ];
  };
  environment = {
    systemPackages = [
      pkgs.mangohud
      pkgs.mangojuice
      pkgs.umu-launcher
      (pkgs.runCommand "ge-proton" { } ''
        mkdir --parents $out/share/steam/compatibilitytools.d/GE-Proton
        ${lib.getExe pkgs.lndir} -silent ${pkgs.proton-ge-bin.steamcompattool} $out/share/steam/compatibilitytools.d/GE-Proton
      '')
    ];
    pathsToLink = [
      "/share/steam"
    ];
  };
  programs = {
    steam = {
      enable = true;
      extraCompatPackages = [
        pkgs.proton-ge-bin
      ];
    };
  };
}
