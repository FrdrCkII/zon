{
  description = "FrdrCkII's Nix Env";
  outputs = _: import ./default.nix;
  nixConfig = {
    flake-registry = "/dev/null";
    allow-import-from-derivation = true;
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      # "https://mirror.nju.edu.cn/nix-channels/store?priority=10"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=15"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=20"
      "https://cache.nixos.org"
    ];
  };
}
