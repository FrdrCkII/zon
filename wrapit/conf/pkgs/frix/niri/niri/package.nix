{
  wrapit,
  frix,
  niri,
  xwayland-satellite,
  pwvucontrol,
  swaylock,
  procps,
  iwmenu,
  wl-clipboard,
  cliphist,
  fyi,
}:
wrapit.wrapthem.override {
  package = niri;
  extraPrograms = [
    frix.niri.wmenu
    frix.niri.aria2
    frix.niri.mako
    frix.niri.fcitx5-switch
    frix.niri.voldown
    frix.niri.volmute
    frix.niri.volup
    frix.ironbar
    frix.foot
    xwayland-satellite
    pwvucontrol
    swaylock
    procps
    iwmenu
    wl-clipboard
    cliphist
    fyi
  ];
  wrapArgs = {
    default = {
      wrapBin = "niri";
      outBin = "niri-desktop";
      appendFlags = [
        "--config"
        "${./niri.kdl}"
        "--session"
      ];
    };
  };
  passthru = {
    configFile = "${./niri.kdl}";
  };
}
