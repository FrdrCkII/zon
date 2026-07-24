let
  github = url: {
    type = "gitArchive";
    url = "https://v6.gh-proxy.org/https://github.com/${url}";
  };
in
{
  config = {
    defaultHashType = "sha256";
  };

  inputs = {
    nixpkgs = {
      type = "channel-mirror-cu";
      url = "https://mirror.nju.edu.cn/nix-channels";
      channel = "nixos-26.05@nixos-26.05";
    };

    dwproton = {
      type = "release";
      url = "https://dawn.wine/dawn-winery/dwproton/releases";
      grep = "x86_64";
    };

    hjem = github "feel-co/hjem";
    agenix = github "ryantm/agenix";
  };

  locked = {
    agenix = {
      meta = {
        fetchUrl = "https://v6.gh-proxy.org/https://github.com/ryantm/agenix/archive/'$NIX_GIT_REV'.tar.gz";
        hashType = "sha256";
        ref = "HEAD";
        rev = null;
        type = "gitArchive";
        url = "https://v6.gh-proxy.org/https://github.com/ryantm/agenix";
      };
      lock = {
        rev = "b027ee29d959fda4b60b57566d64c98a202e0feb";
        url = "https://v6.gh-proxy.org/https://github.com/ryantm/agenix/archive/b027ee29d959fda4b60b57566d64c98a202e0feb.tar.gz";
      };
      prefetch = {
        hash = "sha256-9VnK6Oqai65puVJ4WYtCTvlJeXxMzAp/69HhQuTdl/I=";
        url = "https://v6.gh-proxy.org/https://github.com/ryantm/agenix/archive/b027ee29d959fda4b60b57566d64c98a202e0feb.tar.gz";
      };
      expr = builtins.fetchTarball {
        url = "https://v6.gh-proxy.org/https://github.com/ryantm/agenix/archive/b027ee29d959fda4b60b57566d64c98a202e0feb.tar.gz";
        sha256 = "sha256-9VnK6Oqai65puVJ4WYtCTvlJeXxMzAp/69HhQuTdl/I=";
      };
    };
    dwproton = {
      meta = {
        grep = "x86_64";
        hashType = "sha256";
        type = "release";
        url = "https://dawn.wine/dawn-winery/dwproton/releases";
      };
      lock = {
        url = "https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-11.0-7/dwproton-11.0-7-x86_64.tar.xz";
      };
      prefetch = {
        hash = "sha256-M8wcC7pKFs0Qena5NN9ylq2TykRfPK7JiHnzP6DkZv0=";
        url = "https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-11.0-7/dwproton-11.0-7-x86_64.tar.xz";
      };
      expr = builtins.fetchTarball {
        url = "https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-11.0-7/dwproton-11.0-7-x86_64.tar.xz";
        sha256 = "sha256-M8wcC7pKFs0Qena5NN9ylq2TykRfPK7JiHnzP6DkZv0=";
      };
    };
    hjem = {
      meta = {
        fetchUrl = "https://v6.gh-proxy.org/https://github.com/feel-co/hjem/archive/'$NIX_GIT_REV'.tar.gz";
        hashType = "sha256";
        ref = "HEAD";
        rev = null;
        type = "gitArchive";
        url = "https://v6.gh-proxy.org/https://github.com/feel-co/hjem";
      };
      lock = {
        rev = "35e95ebb9557ac41a72fe00dd55218d1a7f21679";
        url = "https://v6.gh-proxy.org/https://github.com/feel-co/hjem/archive/35e95ebb9557ac41a72fe00dd55218d1a7f21679.tar.gz";
      };
      prefetch = {
        hash = "sha256-rkpUOBv9pVG+GxhK90ebCrFpvjnfP4u2y/iGrzA42K4=";
        url = "https://v6.gh-proxy.org/https://github.com/feel-co/hjem/archive/35e95ebb9557ac41a72fe00dd55218d1a7f21679.tar.gz";
      };
      expr = builtins.fetchTarball {
        url = "https://v6.gh-proxy.org/https://github.com/feel-co/hjem/archive/35e95ebb9557ac41a72fe00dd55218d1a7f21679.tar.gz";
        sha256 = "sha256-rkpUOBv9pVG+GxhK90ebCrFpvjnfP4u2y/iGrzA42K4=";
      };
    };
    nixpkgs = {
      meta = {
        channel = "nixos-26.05@nixos-26.05";
        hashType = "sha256";
        type = "channel-mirror-cu";
        url = "https://mirror.nju.edu.cn/nix-channels";
      };
      lock = {
        url = "https://mirror.nju.edu.cn/nix-channels/releases/nixos-26.05@nixos-26.05.5591.fd1462031fde/nixexprs.tar.xz";
      };
      prefetch = {
        hash = "sha256-IX7j5TvSD7hYC9NZ8mgmq7pZ97mYyl24Qs4Tz4uyvO4=";
        url = "https://mirror.nju.edu.cn/nix-channels/releases/nixos-26.05@nixos-26.05.5591.fd1462031fde/nixexprs.tar.xz";
      };
      expr = builtins.fetchTarball {
        url = "https://mirror.nju.edu.cn/nix-channels/releases/nixos-26.05@nixos-26.05.5591.fd1462031fde/nixexprs.tar.xz";
        sha256 = "sha256-IX7j5TvSD7hYC9NZ8mgmq7pZ97mYyl24Qs4Tz4uyvO4=";
      };
    };
  };
}
