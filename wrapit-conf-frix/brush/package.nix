{
  wrapit,
  brush,
}:
wrapit.wrapthem.override {
  package = brush;
  wrapArgs = {
    default = {
      wrapBin = "brush";
      appendFlags = [
        "--rcfile"
        "/etc/profile"
      ];
    };
  };
}
