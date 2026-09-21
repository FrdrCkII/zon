{ pkgs, ... }: {
  virtualisation = {
    incus = {
      enable = true;
      preseed = {
        networks = [
          {
            name = "incusbr0";
            type = "bridge";
            config = {
              "ipv4.address" = "10.0.100.1/24";
              "ipv4.nat" = "true";
            };
          }
        ];
        storage_pools = [
          {
            name = "default";
            driver = "dir";
            config.source = "/var/lib/incus/storage-pools/default";
          }
        ];
        profiles = [
          {
            name = "default";
            devices = {
              eth0 = {
                type = "nic";
                name = "eth0";
                network = "incusbr0";
              };
              root = {
                type = "disk";
                path = "/";
                pool = "default";
                size = "35GiB";
              };
            };
          }
        ];
      };
    };
  };

  networking.firewall.trustedInterfaces = [
    "incusbr0"
  ];

  programs.captive-browser = {
    enable = true;
    interface = "wlan0";
  };

  users.users.main.packages = [
    pkgs.cargo
    pkgs.rustc
    pkgs.rustfmt
    pkgs.frix.emacs
    pkgs.zed-editor
    pkgs.libreoffice
  ];

  services = {
    flatpak.enable = true;

    scx = {
      enable = true;
      package = pkgs.scx.rustscheds;
      scheduler = "scx_rustland";
    };
  };
}
