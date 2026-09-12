{
  lib,
  stdenvNoCC,
  makeBinaryWrapper,
  hello,
  package ? hello,
  name ? package.name + "-wrapit",
  wrapBin ? package.meta.mainProgram,
  outBin ? wrapBin,
  set ? { },
  setDefault ? { },
  unset ? [ ],
  chdir ? null,
  addFlags ? [ ],
  appendFlags ? [ ],
  prefix ? { },
  suffix ? { },
  argv0 ? "$out/bin/${outBin}",
  extraLibs ? [ ],
  extraPrograms ? [ ],
  extraWrapArgs ? [ ],
  passthru ? { },
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit name;
  allowSubstitute = false;
  allowSubstitutes = false;
  preferLocalBuild = true;
  enableParallelBuilding = true;

  outputs = [ "out" ];

  nativeBuildInputs = [
    makeBinaryWrapper
  ];

  buildInputs = [
    package
  ]
  ++ extraLibs
  ++ extraPrograms;

  preWrapHook = ''
    mkdir --parents $out/bin
  '';

  postWrapHook = "";

  wrapArgs = [
    "--set LD_LIBRARY_PATH '${lib.makeLibraryPath extraLibs}'"
    "--prefix PATH : '${lib.makeBinPath extraPrograms}'"
  ]
  ++ lib.mapAttrsToList (n: v: "--set ${n} ${v}") set
  ++ lib.mapAttrsToList (n: v: "--set-default ${n} ${v}") setDefault
  ++ map (v: "--unset ${v}") unset
  ++ lib.optional (lib.isString chdir) "--chdir ${chdir}"
  ++ map (v: "--add-flag ${v}") addFlags
  ++ map (v: "--add-flag ${v}") appendFlags
  ++ lib.mapAttrsToList (n: v: "--prefix ${n} ${v}") prefix
  ++ lib.mapAttrsToList (n: v: "--suffix ${n} ${v}") suffix
  ++ lib.optional (lib.isString argv0) (
    if argv0 == "inherit" then
      "--inherit-argv0"
    else if argv0 == "resolve" then
      "--resolve-argv0"
    else
      "--argv0 ${argv0}"
  )
  ++ extraWrapArgs;

  buildCommand = ''
    ${finalAttrs.preWrapHook}
    makeBinaryWrapper \
      ${lib.getExe' package wrapBin} $out/bin/${outBin} \
      ${lib.concatStringsSep " " finalAttrs.wrapArgs}
    ${finalAttrs.postWrapHook}
  '';

  passthru = passthru // {
    unwrapped = package;
  };

  meta = package.meta // {
    mainProgram = outBin;
    outputsToInstall = [ "out" ];
  };
})
