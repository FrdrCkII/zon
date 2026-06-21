{
  pkgs,
  lib,
  ...
}:
let
  inherit (import ./share-breeze-dark.nix)
    qt5conf
    qt6conf
    gtk3conf
    gtk4conf
    ;
in
{
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };
  programs = {
    dconf.profiles = {
      user.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              gtk-theme = "Breeze-Dark";
              gtk-icon-theme-name = "breeze-dark";
              color-scheme = "prefer-dark";
              cursor-theme = "Vanilla-DMZ-AA";
              cursor-size = lib.gvariant.mkInt32 16;
            };
          };
        }
      ];
    };
  };
  environment = {
    systemPackages = [
      pkgs.kdePackages.breeze
      pkgs.kdePackages.breeze.qt5
      pkgs.kdePackages.breeze-icons
      pkgs.kdePackages.breeze-gtk
      pkgs.vanilla-dmz
      (pkgs.runCommand "curserTheme" { } ''
        mkdir --parents $out/share/icons/default
        echo "[Icon Theme]
        Name=Default
        Comment=Default Cursor Theme
        Inherits=Vanilla-DMZ-AA" \
        > $out/share/icons/default/index.theme
      '')
    ];
    etc = {
      "xdg/qt5ct/qt5ct.conf".text = qt5conf pkgs;
      "xdg/qt6ct/qt6ct.conf".text = qt6conf pkgs;
      "gtk-3.0/settings.ini".text = gtk3conf;
      "gtk-4.0/gtk.css".source = "${pkgs.kdePackages.breeze-gtk}/share/themes/gtk-4.0/gtk.css";
      "gtk-4.0/settings.ini".text = gtk4conf;
    };
  };
}
