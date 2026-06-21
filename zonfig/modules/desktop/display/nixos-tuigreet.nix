{
  config,
  pkgs,
  lib,
  ...
}:
let
  sessionsDir = "${config.services.displayManager.sessionData.desktops}/share";
in
{
  config = {
    users.users.greeter = {
      isNormalUser = false;
      extraGroups = [ "seat" ];
    };
    security.pam.services = {
      greetd.enableGnomeKeyring = true;
      greetd-password.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
    };
    services.greetd = {
      enable = true;
      restart = true;
      useTextGreeter = true;
      settings = {
        default_session = {
          user = "greeter";
          command = lib.concatStringsSep " " [
            (lib.getExe pkgs.tuigreet)
            "--time"
            "--remember"
            "--remember-session"
            "--asterisks"
            "--user-menu"
            "--sessions"
            "${sessionsDir}/wayland-sessions"
            "--xsessions"
            "${sessionsDir}/xsessions"
          ];
        };
      };
    };
  };
}
