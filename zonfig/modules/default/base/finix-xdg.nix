_: {
  config = {
    security.pam.environment = {
      XDG_CACHE_HOME.default = "$HOME/.cache";
      XDG_CONFIG_HOME.default = "$HOME/.config";
      XDG_DATA_HOME.default = "$HOME/.local/share";
      XDG_STATE_HOME.default = "$HOME/.local/state";
    };
  };
}
