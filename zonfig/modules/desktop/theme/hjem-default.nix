{ pkgs, ... }:
let
  inherit (import ./share-breeze-dark.nix)
    qt5conf
    qt6conf
    gtk3conf
    gtk4conf
    ;
in
{
  xdg.config.files = {
    "qt5ct/qt5ct.conf".text = qt5conf pkgs;
    "qt6ct/qt6ct.conf".text = qt6conf pkgs;
    "gtk-3.0/settings.ini".text = gtk3conf;
    "gtk-4.0/gtk.css".source = "${pkgs.kdePackages.breeze-gtk}/share/themes/gtk-4.0/gtk.css";
    "gtk-4.0/settings.ini".text = gtk4conf;
  };
}
