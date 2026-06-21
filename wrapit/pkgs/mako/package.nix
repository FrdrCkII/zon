{
  lib,
  writeText,
  wrapit,
  mako,
  settings ? { },
  extraConfig ? "",
}:
let
  generateConfig =
    config:
    let
      formatValue = v: if builtins.isBool v then if v then "true" else "false" else toString v;

      globalSettings = lib.filterAttrs (_n: v: !(lib.isAttrs v)) config;
      sectionSettings = lib.filterAttrs (_n: v: lib.isAttrs v) config;

      globalLines = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (k: v: "${k}=${formatValue v}") globalSettings
      );

      formatSection =
        name: attrs:
        "\n[${name}]\n"
        + lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${formatValue v}") attrs);

      sectionLines = lib.concatStringsSep "\n" (lib.mapAttrsToList formatSection sectionSettings);
    in
    lib.concatStringsSep "\n" [
      globalLines
      sectionLines
      extraConfig
    ];
in
wrapit.wrapthem.override {
  package = mako;
  wrapArgs = {
    default.appendFlags = [
      "--config"
      "${writeText "mako.conf" (generateConfig settings)}"
    ];
  };
}
