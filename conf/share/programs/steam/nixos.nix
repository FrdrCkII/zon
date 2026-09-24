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
      package = pkgs.steam.override {
        extraLibraries = pkgs: [
          pkgs.libXcursor
          pkgs.libXi
          pkgs.libXinerama
          pkgs.libXScrnSaver
          pkgs.libpng
          pkgs.libpulseaudio
          pkgs.libvorbis
          pkgs.stdenv.cc.cc.lib
          pkgs.libkrb5

          pkgs.SDL2
          pkgs.libxkbcommon
          pkgs.wayland
          pkgs.libdecor
        ];

        extraPkgs = pkgs: [
          pkgs.xrandr
          pkgs.xdpyinfo
          pkgs.xprop

          pkgs.pciutils
          pkgs.usbutils
          pkgs.keyutils
          pkgs.mesa-demos
          pkgs.vulkan-tools
          pkgs.lshw
        ];
      };

      extraCompatPackages = [
        pkgs.proton-ge-bin
      ];
    };

    gamescope = {
      enable = true;
      env = {
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
    };
  };
}
