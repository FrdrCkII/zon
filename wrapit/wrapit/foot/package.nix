{
  lib,
  wrapit,
  formats,
  foot,
  settings ? { },
}:
let
  iniFormat = formats.ini { listsAsDuplicateKeys = true; };
  configFile =
    if lib.isPath settings then
      settings
    else if lib.isAttrs settings then
      iniFormat.generate "foot.ini" settings
    else
      iniFormat.generate "foot.ini" { };
in
wrapit.wrapthem.override {
  package = foot;
  wrapArgs = {
    default = {
      wrapBin = "foot";
      appendFlags = [ "--config=${configFile}" ];
    };
  };
}
