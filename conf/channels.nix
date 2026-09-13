let
  locked = builtins.fromJSON (builtins.readFile ./channels.lock);

  github = url: {
    type = "gitArchive";
    url = "https://v6.gh-proxy.org/https://github.com/${url}";
  };
in
{
  inputs = {
    hjem = github "feel-co/hjem";
    agenix = github "ryantm/agenix";
    nixos-core = github "manic-systems/nixos-core";
    ncro = github "manic-systems/ncro";

    nixpkgs = {
      type = "nixpkgsCn";
      url = "https://mirror.nju.edu.cn/nix-channels/releases";
      channel = "nixos-unstable@nixos-";
    };
  };

  inherit locked;
  expr = builtins.mapAttrs (
    n: v:
    builtins.fetchTarball {
      inherit (v) url;
      sha256 = v.hash;
    }
  ) locked;
}
