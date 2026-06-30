_: {
  config = {
    services.displayManager.emptty = {
      enable = true;
      settings = {
        DEFAULT_ENV = "wayland";
        DEFAULT_SESSION_ENV = "wayland";
        VERTICAL_SELECTION = true;
      };
    };
  };
}
