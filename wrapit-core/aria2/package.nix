{
  formats,
  wrapit,
  aria2,
  settings ? { },
}:
let
  keyValueFormat = formats.keyValue { };
in
wrapit.wrapthem.override {
  package = aria2;
  wrapArgs = {
    default.appendFlags = [
      "--conf-path"
      "${keyValueFormat.generate "aria2.conf" settings}"
    ];
  };
}
