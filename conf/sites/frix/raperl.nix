{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.nixos-core.nixosModules.default
    inputs.ncro.nixosModules.default
  ];

  # options conflict with nixos-core
  system.etc.overlay.enable = lib.mkForce false;
  services.userborn.enable = lib.mkForce false;
  systemd.sysusers.enable = lib.mkForce false;

  system.nixos-core.enable = true;

  nix.settings.substituters = lib.mkForce (lib.singleton "http://localhost:9010");
  services.ncro = {
    enable = true;
    settings = {
      logging.timestamps = false;

      server = {
        listen = ":9010";
        cache_priority = 20;
      };

      upstreams = [
        {
          url = "https://mirror.nju.edu.cn/nix-channels/store";
          priority = 40;
          public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        }
        {
          url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store";
          priority = 40;
          public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        }
        {
          url = "https://mirrors.ustc.edu.cn/nix-channels/store";
          priority = 40;
          public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        }
        {
          url = "https://mirror.sjtu.edu.cn/nix-channels/store";
          priority = 40;
          public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        }

        {
          url = "https://cache.nixos.org";
          priority = 50;
          public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        }

        {
          url = "https://cache.nixos-cuda.org/";
          priority = 90;
          public_key = "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=";
        }

        {
          url = "https://nix-community.cachix.org";
          priority = 100;
          public_key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
        }
      ];
    };
  };
}
