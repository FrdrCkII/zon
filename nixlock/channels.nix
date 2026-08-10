{
  config = {
    defaultHashType = "sha256";
  };

  inputs = {
    nixpkgs = {
      type = "tarball";
      url = "https://mirror.nju.edu.cn/nix-channels/releases/nixos-26.05@nixos-26.05.5591.fd1462031fde/nixexprs.tar.xz";
    };

    nixpkgs-unstable = {
      type = "tarball";
      url = "https://mirror.nju.edu.cn/nix-channels/nixpkgs-unstable/nixexprs.tar.xz";
    };
  };

  locked = {
    nixpkgs = {
      meta = {
        hashType = "sha256";
        type = "tarball";
        url = "https://mirror.nju.edu.cn/nix-channels/releases/nixos-26.05@nixos-26.05.5591.fd1462031fde/nixexprs.tar.xz";
      };
      fetch = {
        url = "https://mirror.nju.edu.cn/nix-channels/releases/nixos-26.05@nixos-26.05.5591.fd1462031fde/nixexprs.tar.xz";
        hash = "sha256-S4rqQcQbBmKAWuMt3pdZsf8PmccEarzIRfp4dIXgN8M=";
      };
      expr = builtins.fetchTarball {
        url = "https://mirror.nju.edu.cn/nix-channels/releases/nixos-26.05@nixos-26.05.5591.fd1462031fde/nixexprs.tar.xz";
        sha256 = "sha256-S4rqQcQbBmKAWuMt3pdZsf8PmccEarzIRfp4dIXgN8M=";
      };
    };
    nixpkgs-unstable = {
      meta = {
        hashType = "sha256";
        type = "tarball";
        url = "https://mirror.nju.edu.cn/nix-channels/nixpkgs-unstable/nixexprs.tar.xz";
      };
      fetch = {
        url = "https://mirror.nju.edu.cn/nix-channels/nixpkgs-unstable/nixexprs.tar.xz";
        hash = "sha256-KC0oIGWMjA8zHWQe2XaJyc1+TUwwVzPEge22xdu+0N4=";
      };
      expr = builtins.fetchTarball {
        url = "https://mirror.nju.edu.cn/nix-channels/nixpkgs-unstable/nixexprs.tar.xz";
        sha256 = "sha256-KC0oIGWMjA8zHWQe2XaJyc1+TUwwVzPEge22xdu+0N4=";
      };
    };
  };
}
