{
  lib,
  wrapit,
  buildEnv,
  hello,
  package ? hello,
  name ? package.name + "-wrapit",
  extraPrograms ? [ ],
  wrapArgs ? { },
  passthru ? { },
}:
buildEnv (finalAttrs: {
  inherit name;
  ignoreCollisions = true;
  extraOutputsToInstall = [
    "out"
    "bin"
    "lib"
  ];

  paths =
    (lib.mapAttrsToList (_: v: wrapit.wrapit.override (v // { inherit package; })) wrapArgs)
    ++ extraPrograms
    ++ [ package ];

  passthru =
    passthru
    // package.passthru
    // {
      unwrapped = package;
      config = { inherit extraPrograms wrapArgs passthru; };
      wrap =
        {
          extraPrograms ? [ ],
          wrapArgs ? { },
          passthru ? { },
        }:
        wrapit.wrapthem.override {
          inherit name package;
          extraPrograms = finalAttrs.passthru.config.extraPrograms // extraPrograms;
          wrapArgs = finalAttrs.passthru.config.wrapArgs // wrapArgs;
          passthru = finalAttrs.passthru.config.passthru // passthru;
        };
    };
})
