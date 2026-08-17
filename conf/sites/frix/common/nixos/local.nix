{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  time = {
    timeZone = mkDefault "Asia/Shanghai";
  };
  networking = {
    timeServers = [
      "time.pool.aliyun.com"
      "cn.pool.ntp.org"
      "ntp.ntsc.ac.cn"
    ];
  };
  nix.settings = {
    substituters = [
      # "https://mirror.nju.edu.cn/nix-channels/store?priority=10"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=15"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=20"
    ];
    trusted-substituters = [
      # "https://mirror.nju.edu.cn/nix-channels/store?priority=10"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=15"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=20"
    ];
  };
  i18n = {
    defaultLocale = mkDefault "zh_CN.UTF-8";
    extraLocaleSettings.LC_MESSAGES = mkDefault "en_US.UTF-8";
  };
  fonts = {
    enableDefaultPackages = false;
    enableGhostscriptFonts = false;
    packages = [
      pkgs.maple-mono.NF-CN
      pkgs.noto-fonts-color-emoji
      pkgs.unifont
    ];
    fontDir = {
      enable = true;
      decompressFonts = true;
    };
    fontconfig = {
      enable = true;
      cache32Bit = true;
      includeUserConf = false;
      allowBitmaps = false;
      defaultFonts = {
        serif = lib.mkBefore [
          "Maple Mono NF CN"
          "Unifont"
        ];
        sansSerif = lib.mkBefore [
          "Maple Mono NF CN"
          "Unifont"
        ];
        monospace = lib.mkBefore [
          "Maple Mono NF CN"
          "Unifont"
        ];
        emoji = lib.mkBefore [
          "Noto Color Emoji"
          "Unifont"
        ];
      };
    };
  };
}
