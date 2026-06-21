{ ... }: {
  config = {
    services.displayManager.ly = {
      enable = true;
      x11Support = true;
      settings = {
        save = false;
        brightness_down_cmd = null;
        brightness_up_cmd = null;
        brightness_down_key = null;
        brightness_up_key = null;
        session_log = ".local/state/ly-session.log";
        xinitrc = null;
      };
    };
  };
}
