let
  github = repo: {
    ftype = "gitArchive";
    repo = "https://v6.gh-proxy.org/https://github.com/${repo}";
  };
in
{
  config = {
    # autoFollow = false;
  };

  inputs = {
    hjem = github "feel-co/hjem";
    agenix = github "ryantm/agenix";
    stylix = github "nix-community/stylix";

    nixpkgs = {
      ftype = "nixpkgsMirror";
      mirror = "https://mirror.nju.edu.cn/nix-channels";
      channel = "nixos-26.05@nixos-26.05";
    };
  };

  locked = builtins.mapAttrs (
    n: v:
    builtins.fetchTarball {
      url = v.locked.immut;
      sha256 = v.locked.hash;
    }
  ) (builtins.fromJSON (builtins.readFile ./channels.lock)).locked.top;
}
