{
  qt5conf = pkgs: ''
    [Appearance]
    color_scheme=darker
    color_scheme_path=${pkgs.libsForQt5.qt5ct}/share/qt5ct/colors/darker.conf
    custom_palette=true
    icon_theme=breeze-dark
    standard_dialogs=default
    style=Breeze
  '';
  qt6conf = pkgs: ''
    [Appearance]
    color_scheme=darker
    color_scheme_path=${pkgs.kdePackages.qt6ct}/share/qt6ct/colors/darker.conf
    custom_palette=true
    icon_theme=breeze-dark
    standard_dialogs=default
    style=Breeze
  '';
  gtk3conf = ''
    [Settings]
    gtk-theme-name=Breeze-Dark
    gtk-icon-theme-name=breeze-dark
    gtk-font-name=monospace 12
    gtk-cursor-theme-name=Vanilla-DMZ-AA
    gtk-cursor-theme-size=16
    gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
    gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
    gtk-button-images=0
    gtk-menu-images=0
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=0
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintslight
    gtk-xft-rgba=rgb
  '';
  gtk4conf = ''
    [Settings]
    gtk-theme-name=Breeze-Dark
    gtk-icon-theme-name=breeze-dark
    gtk-font-name=monospace 12
    gtk-cursor-theme-name=Vanilla-DMZ-AA
    gtk-cursor-theme-size=16
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=0
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintslight
    gtk-xft-rgba=rgb
  '';
}
