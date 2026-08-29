{
  config,
  pkgs,
  lib,
  ...
}:
let
  mkDesktopEntry =
    name: text:
    pkgs.writeTextFile {
      inherit name text;
      destination = "/share/wayland-sessions/${name}.desktop";
      derivationArgs = {
        passthru.providedSessions = [ name ];
      };
    };
in
{
  options = {
    desktop.niri = lib.mkOption {
      type = lib.types.package;
      default = pkgs.frix.niri.niri;
    };
  };

  config = {
    programs = {
      thunar = {
        enable = true;
        plugins = [
          pkgs.thunar-archive-plugin
          pkgs.thunar-volman
          pkgs.tumbler
        ];
      };
    };

    services = {
      displayManager.sessionPackages = [
        (mkDesktopEntry "niri" ''
          [Desktop Entry]
          Name=Niri
          Comment=Niri
          Exec=/run/current-system/sw/bin/niri-session
          Type=Application
        '')
      ];
    };

    xdg = {
      portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-wlr
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-gnome
        ];
        config = {
          niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Settings" = [ "darkman" ];
            "org.freedesktop.impl.portal.Access" = "gtk";
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
            "org.freedesktop.impl.portal.Notification" = "gtk";
            "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
          };
        };
      };
      mime.defaultApplications = {
        "inode/directory" = "thunar.desktop";
      };
    };

    security = {
      pam.services.swaylock = { };
      soteria.enable = true;
    };

    environment = {
      etc = {
        "niri/config.kdl".source = config.desktop.niri.configFile;
      };
      systemPackages = [
        config.desktop.niri
      ];
      sessionVariables = {
        NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland";
        GDK_BACKEND = "wayland,x11";
        CLUTTER_BACKEND = "wayland";
        WLR_RENDERER_ALLOW_SOFTWARE = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
        WLR_RENDERER = "vulkan";
      };
    };
  };
}
