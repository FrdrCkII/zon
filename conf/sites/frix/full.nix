{ pkgs, ... }: {
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
