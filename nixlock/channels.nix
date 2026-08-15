let
  github = url: {
    type = "gitArchive";
    url = "https://v6.gh-proxy.org/https://github.com/${url}";
  };
in
{
  inputs = {
    hjem = github "feel-co/hjem";
    agenix = github "ryantm/agenix";

    nixpkgs = {
      type = "nixpkgsCn";
      url = "https://mirror.nju.edu.cn/nix-channels/releases";
      channel = "nixos-26.05@nixos-26.05";
    };

    dwproton = {
      type = "forgejoRelease";
      domain = "dawn.wine";
      repo = "dawn-winery/dwproton";
      grep = "x86_64.tar.xz";
    };
  };

  locked = builtins.mapAttrs (
    n: v:
    builtins.fetchTarball {
      url = v.url;
      sha256 = v.hash;
    }
  ) (builtins.fromJSON (builtins.readFile ./channels.lock));
}
