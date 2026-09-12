{
  lib,
  stdenvNoCC,
  proton-ge-bin,
  lndir,
  # Can be overridden to alter the display name in steam
  # This could be useful if multiple versions should be installed together
  steamDisplayName ? "GE-Proton",
  src ? proton-ge-bin.src,
  pname ? lib.getName proton-ge-bin,
  version ? lib.getVersion proton-ge-bin,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit src pname version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  outputs = [
    "out"
    "steamcompattool"
  ];

  installPhase = ''
    runHook preInstall

    mkdir --parents $out/share/steam/compatibilitytools.d/${steamDisplayName}
    ${lib.getExe lndir} -silent ${src} $out/share/steam/compatibilitytools.d/${steamDisplayName}

    mkdir $steamcompattool
    ln -s $src/* $steamcompattool
    rm $steamcompattool/compatibilitytool.vdf
    cp $src/compatibilitytool.vdf $steamcompattool

    runHook postInstall
  '';

  preFixup = ''
    substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
      --replace-fail "${finalAttrs.version}" "${steamDisplayName}"
  '';

  meta = {
    description = ''
      Compatibility tool for Steam Play based on Wine and additional components.

      (This is intended for use in the `programs.steam.extraCompatPackages` option only.)
    '';
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
