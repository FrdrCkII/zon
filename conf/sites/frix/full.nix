{ pkgs, ... }: {
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };

  environment = {
    etc."containers/registries.conf.d/00-mirrors.conf".text = ''
      [[registry]]
      prefix = "docker.io"
      location = "docker.io"
      mirror = [
        { location = "docker.m.daocloud.io" },
        { location = "docker.1ms.run" }
      ]
    '';

    systemPackages = [
      pkgs.distrobox
    ];
  };

  users.users.main.packages = [
    pkgs.cargo
    pkgs.rustc
    pkgs.rustfmt
    pkgs.frix.emacs
    pkgs.zed-editor
    pkgs.libreoffice
  ];

  services.scx = {
    enable = true;
    package = pkgs.scx.rustscheds;
    scheduler = "scx_rustland";
  };
}
