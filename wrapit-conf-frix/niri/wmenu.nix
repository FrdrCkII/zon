{
  wrapit,
  wmenu,
}:
wrapit.wrapthem.override {
  package = wmenu;
  wrapArgs = {
    wmenu = {
      wrapBin = "wmenu";
      appendFlags = [
        "-i"
        "-l"
        "10"
        "-f"
        "\"monospace 12\""
      ];
    };
    run = {
      wrapBin = "wmenu-run";
      appendFlags = [
        "-i"
        "-l"
        "10"
        "-f"
        "\"monospace 12\""
      ];
    };
  };
}
