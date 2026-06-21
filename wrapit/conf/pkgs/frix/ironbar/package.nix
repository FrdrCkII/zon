{
  wrapit,
  ironbar,
}:
wrapit.wrapthem.override {
  package = ironbar;
  wrapArgs = {
    default = {
      outBin = "ironbar";
      appendFlags = [
        "--config"
        "${./ironbar.toml}"
        "--theme"
        "${./ironbar.css}"
      ];
    };
  };
}
